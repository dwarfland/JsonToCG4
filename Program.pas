namespace JsonCG4;

uses
  RemObjects.CodeGen4;

type
  Program = class
  public

    class method Main(args: array of String): Int32;
    begin
      // add your own code here
      writeLn('The magic happens here.');

      //
      // Load the sample .json file.
      //

      var lJson := JsonDocument.FromFile("../../json.json");

      //
      // Process it using our JsonToCG class
      //

      var lJsonToCG := new JsonToCG withDocument(lJson);

      //
      // Print the geneated code, as Oxygene and C# (any other CG*CodeGenerator will work too)
      //

      var lOxygeneCG := new CGOxygeneCodeGenerator withStyle(CGOxygeneCodeGeneratorStyle.Unified) quoteStyle(CGOxygeneStringQuoteStyle.SmartDouble);
      writeLn(lOxygeneCG.GenerateUnit(lJsonToCG.Unit));

      var lCSharpCG := new CGCSharpCodeGenerator withDialect(CGCSharpCodeGeneratorDialect.Hydrogene);
      writeLn(lCSharpCG.GenerateUnit(lJsonToCG.Unit));

      //
      // Test the generated code (which is in Test.pas, for convenience)
      //

      var lRoot := new Root(lJson.Root as JsonObject);
      writeLn($"lRoot.Name {lRoot.Name}");
      writeLn($"lRoot.Version {lRoot.Version}");

      for i := 0 to lRoot.Items.Count-1 do begin
        writeLn($"lRoot.Items[{i}] {lRoot.Items[i]}");
        writeLn($"lRoot.Items[{i}].Bar {lRoot.Items[i].Bar}");
        writeLn($"lRoot.Items[{i}].Baz {lRoot.Items[i].Baz}");
        writeLn($"lRoot.Items[{i}].Foo {lRoot.Items[i].Foo}");
      end;

      var lSum := 0;
      for each i in lRoot.Numbers do begin
        writeLn($"lRoot.Numbers {i}");
        inc(lSum, i);
      end;
      writeLn($"lSum {lSum}");

      for i := 0 to lRoot.Nested.Count-1 do begin
        for j := 0 to lRoot.Nested[i].Count-1 do begin
          writeLn($"lRoot.Nested[{i}][{j}] {lRoot.Nested[i][j]}");
          inc(lSum, lRoot.Nested[i][j]);
        end;
      end;
      writeLn($"lSum {lSum}");

    end;

  end;

end.