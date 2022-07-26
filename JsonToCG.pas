namespace JsonCG4;

uses RemObjects.CodeGen4;

type
  JsonToCG = public class
  public

    constructor withFile(aFile: not nullable String);
    begin
      constructor withDocument(JsonDocument.FromFile(aFile))
    end;

    constructor withDocument(aJson: not nullable JsonDocument);
    begin
      fUnit := new CGCodeUnit();
      ProcessJsonNode("Root", "Root", aJson.Root);
    end;

    //
    //
    //

    var JsonNodeTypeReference := "RemObjects.Elements.RTL.JsonNode".AsTypeReference;
    var JsonObjectTypeReference := "RemObjects.Elements.RTL.JsonObject".AsTypeReference;
    var JsonArrayTypeReference := "RemObjects.Elements.RTL.JsonArray".AsTypeReference;

    //
    // Determine the type and property getter code for reading a specific node.
    //

    method TypeAndExpressionForJsonNode(aName: String; aPath: String; aNodeType: not nullable &Type; aNode: nullable JsonNode; aGetExpression: not nullable CGExpression): tuple of (CGTypeReference, CGExpression);
    begin
      var lType := TypeForJsonNode(aName, aPath, aNodeType, aNode, aGetExpression);
      var lExpression := ExpressionForJsonNode(aName, aPath, aNodeType, aNode, aGetExpression);
      CGMemberAccessExpression(lExpression):NilSafe := true;
      result := (lType, lExpression);
    end;

    method TypeForJsonNode(aName: String; aPath: String; aNodeType: not nullable &Type; aNode: nullable JsonNode; aGetExpression: not nullable CGExpression): CGTypeReference;
    begin
      result := case aNodeType of
        JsonObject:       ProcessJsonObject(aPath, aNode as JsonObject);
        JsonArray:        ProcessJsonArray(aPath, aNode as JsonArray);
        JsonStringValue:  CGPredefinedTypeReference.String;
        JsonIntegerValue: CGPredefinedTypeReference.Int64;
        JsonFloatValue:   CGPredefinedTypeReference.Double;
        JsonBooleanValue: CGPredefinedTypeReference.Boolean;
      end;
    end;

    method ExpressionForJsonNode(aName: String; aPath: String; aNodeType: not nullable &Type; aNode: nullable JsonNode; aGetExpression: not nullable CGExpression): CGExpression;
    begin
      result := case aNodeType of
        JsonObject:       new CGNewInstanceExpression(aPath.AsTypeReference, new CGTypeCastExpression(aGetExpression, JsonObjectTypeReference, true).AsCallParameter);
        JsonArray:        new CGNewInstanceExpression(aPath.AsTypeReference, new CGTypeCastExpression(aGetExpression, JsonArrayTypeReference, true).AsCallParameter);
        JsonStringValue:  new CGPropertyAccessExpression(aGetExpression, "StringValue");
        JsonIntegerValue: new CGPropertyAccessExpression(aGetExpression, "IntegerValue");
        JsonFloatValue:   new CGPropertyAccessExpression(aGetExpression, "FloatValue");
        JsonBooleanValue: new CGPropertyAccessExpression(aGetExpression, "BooleanValue");
      end;
      //CGMemberAccessExpression(result):NilSafe := true;
    end;

    method FindOrCreateClass(aName: String): CGClassTypeDefinition;
    begin
      result := fUnit.Types:FirstOrDefault(c -> c.Name = aName) as CGClassTypeDefinition;
      if not assigned(result) then begin

        result := new CGClassTypeDefinition(aName);
        result.Visibility := CGTypeVisibilityKind.Public;

        var lConstructor := new CGConstructorDefinition();
        lConstructor.Parameters.Add(new CGParameterDefinition("aNode", JsonObjectTypeReference));
        lConstructor.Visibility := CGMemberVisibilityKind.Public;
        lConstructor.Statements.Add(new CGAssignmentStatement(new CGFieldAccessExpression(CGSelfExpression.Self, "fNode"), new CGLocalVariableAccessExpression("aNode")));
        result.Members.Add(lConstructor);

        var lField := new CGFieldDefinition("fNode", JsonObjectTypeReference);
        lField.Visibility := CGMemberVisibilityKind.Private;
        result.Members.Add(lField);

        fUnit.Types.Add(result);
      end;
    end;

    method ClassHasProperty(aClass: not nullable CGClassTypeDefinition; aName: not nullable String): Boolean;
    begin
      result := aClass.Members.Any(p -> p.Name = aName);
    end;

    method CreateProperty(aName: String; aPropertyType: CGTypeReference; aExpression: CGExpression): CGPropertyDefinition;
    begin
      result := new CGPropertyDefinition(aName);
      result.Type := aPropertyType;
      result.Visibility := CGMemberVisibilityKind.Public;
      result.GetExpression := aExpression;
    end;

    //
    // Create (or extend, in case of arrays) the class for a Json object at a given location in the tree
    //

    method ProcessJsonNode(aName: String; aPath: String; aNode: not nullable JsonNode): tuple of (CGTypeReference, CGExpression);
    begin
      var lElementGet := new CGArrayElementAccessExpression(new CGFieldAccessExpression(CGSelfExpression.Self, "fNode"), aName.AsLiteralExpression);
      result := TypeAndExpressionForJsonNode(aName, aPath, typeOf(aNode), aNode, lElementGet);
    end;

    method ProcessJsonObject(aName: String; aNode: not nullable JsonObject): CGTypeReference;
    begin
      var lClass := FindOrCreateClass(aName);
      for each k in aNode.Keys do begin
        if not ClassHasProperty(lClass, k) then begin
          var (lPropertyType, lInitExpression) := ProcessJsonNode(k, aName+"_"+k, aNode[k]);
          if assigned(lPropertyType) then
            lClass.Members.Add(CreateProperty(k, lPropertyType, lInitExpression))
          else
            writeLn($"Unexpected node type {aNode[k]}");
        end;
      end;
      result := aName.AsTypeReference;
    end;

    //
    // Create the class for a Json array at a given location in the tree
    //

    method ProcessJsonArray(aName: String; aNode: not nullable JsonArray): CGTypeReference;
    begin
      var lNodeType: RemObjects.Elements.RTL.Reflection.Type;
      var lUniform := true;
      for each e in aNode do begin
        if assigned(lNodeType) and (lNodeType ≠ typeOf(e)) then
          lUniform := false;
        lNodeType := typeOf(e)
      end;

      var lElementGet := new CGArrayElementAccessExpression(new CGFieldAccessExpression(CGSelfExpression.Self, "fNode"), new CGLocalVariableAccessExpression("aIndex"));

      var lClassName: String;
      var lType: CGTypeReference;
      var lExpression: CGExpression;
      if lUniform then begin
        case lNodeType of
          JsonObject: begin
              lClassName := aName+"_ArrayItem";
              for each e in aNode do
                lType := ProcessJsonObject(lClassName, e as JsonObject);
              (nil, lExpression) := TypeAndExpressionForJsonNode(nil, lClassName, lNodeType, aNode.First, lElementGet);
            end;
          JsonArray: begin
              lClassName := aName+"_SubArray";
              (lType, lExpression) := TypeAndExpressionForJsonNode(nil, lClassName, lNodeType, aNode.First, lElementGet);
            end;
          else begin
              (lType, lExpression) := TypeAndExpressionForJsonNode(nil, nil, lNodeType, nil, lElementGet);
            end;
        end;
      end
      else begin
        lType := JsonNodeTypeReference; // for mixed arrays, we just return the JsonNode
        lExpression := lElementGet;
      end;


      var lWrapperType := new CGClassTypeDefinition(aName);
      lWrapperType.Visibility := CGTypeVisibilityKind.Public;
      fUnit.Types.Add(lWrapperType);

      var lConstructor := new CGConstructorDefinition();
      lConstructor.Parameters.Add(new CGParameterDefinition("aNode", JsonArrayTypeReference));
      lConstructor.Visibility := CGMemberVisibilityKind.Public;
      lConstructor.Statements.Add(new CGAssignmentStatement(new CGFieldAccessExpression(CGSelfExpression.Self, "fNode"), new CGLocalVariableAccessExpression("aNode")));
      lWrapperType.Members.Add(lConstructor);

      var lField := new CGFieldDefinition("fNode", JsonArrayTypeReference);
      lField.Visibility := CGMemberVisibilityKind.Private;
      lWrapperType.Members.Add(lField);

      var lCountProperty := new CGPropertyDefinition("Count", CGPredefinedTypeReference.Int64);
      lCountProperty.Visibility := CGMemberVisibilityKind.Public;
      lCountProperty.GetExpression := new CGPropertyAccessExpression(new CGFieldAccessExpression(CGSelfExpression.Self, "fNode"), "Count");
      lWrapperType.Members.Add(lCountProperty);

      var lItemsProperty := new CGPropertyDefinition("Items", lType);
      lItemsProperty.Parameters.Add(new CGParameterDefinition("aIndex", CGPredefinedTypeReference.Int64));
      lItemsProperty.Visibility := CGMemberVisibilityKind.Public;
      lItemsProperty.GetExpression := lExpression;
      lItemsProperty.Default := true;
      lWrapperType.Members.Add(lItemsProperty);

      var lSequence := new CGMethodDefinition("GetSequence");
      lSequence.Visibility := CGMemberVisibilityKind.Public;
      lSequence.Attributes.Add(new CGAttribute("Sequence".AsTypeReference));
      lSequence.ReturnType := new CGSequenceTypeReference(lType);
      if lUniform then begin

        var lLocalGet := new CGLocalVariableAccessExpression("n");
        var lLocalExpression := ExpressionForJsonNode(nil, lClassName, lNodeType, aNode.First, lLocalGet);

        var aAnon := new CGAnonymousMethodExpression();
        aAnon.Lambda := true;
        aAnon.Parameters.Add(new CGParameterDefinition("n"));
        aAnon.Statements.Add(new CGReturnStatement(lLocalExpression));
        lSequence.Statements.Add(new CGReturnStatement(new CGMethodCallExpression(new CGFieldAccessExpression(CGSelfExpression.Self, "fNode"), "Select", aAnon.AsCallParameter)));
      end
      else begin
        lSequence.Statements.Add(new CGReturnStatement(new CGFieldAccessExpression(CGSelfExpression.Self, "fNode")));
      end;
      lWrapperType.Members.Add(lSequence);

      result := aName.AsTypeReference;
    end;

    //
    //
    //

    property &Unit: CGCodeUnit read fUnit;
    property RootType: CGTypeReference read private write;

  private
    fUnit: CGCodeUnit;
  end;

end.