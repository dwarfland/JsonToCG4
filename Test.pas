namespace;

type
	Root = public class
	private

		constructor(aNode: RemObjects.Elements.RTL.JsonObject); public;
		begin
			self.fNode := aNode;
		end;

		var fNode: RemObjects.Elements.RTL.JsonObject; private;

		property Name: String read self.fNode["Name"]:StringValue; public;


		property Version: Int64 read self.fNode["Version"]:IntegerValue; public;


		property Items: Root_Items read new Root_Items((self.fNode["Items"] as RemObjects.Elements.RTL.JsonArray)); public;


		property Numbers: Root_Numbers read new Root_Numbers((self.fNode["Numbers"] as RemObjects.Elements.RTL.JsonArray)); public;


		property &Nested: Root_Nested read new Root_Nested((self.fNode["Nested"] as RemObjects.Elements.RTL.JsonArray)); public;


		property Mixed: Root_Mixed read new Root_Mixed((self.fNode["Mixed"] as RemObjects.Elements.RTL.JsonArray)); public;


	end;

	Root_Items_ArrayItem = public class
	private

		constructor(aNode: RemObjects.Elements.RTL.JsonObject); public;
		begin
			self.fNode := aNode;
		end;

		var fNode: RemObjects.Elements.RTL.JsonObject; private;

		property Foo: Int64 read self.fNode["Foo"]:IntegerValue; public;


		property Bar: Boolean read self.fNode["Bar"]:BooleanValue; public;


		property Baz: Root_Items_ArrayItem_Baz read new Root_Items_ArrayItem_Baz((self.fNode["Baz"] as RemObjects.Elements.RTL.JsonObject)); public;


	end;

	Root_Items_ArrayItem_Baz = public class
	private

		constructor(aNode: RemObjects.Elements.RTL.JsonObject); public;
		begin
			self.fNode := aNode;
		end;

		var fNode: RemObjects.Elements.RTL.JsonObject; private;

	end;

	Root_Items = public class
	private

		constructor(aNode: RemObjects.Elements.RTL.JsonArray); public;
		begin
			self.fNode := aNode;
		end;

		var fNode: RemObjects.Elements.RTL.JsonArray; private;

		property Count: Int64 read self.fNode.Count; public;


		property Items[aIndex: Int64]: Root_Items_ArrayItem read new Root_Items_ArrayItem((self.fNode[aIndex] as RemObjects.Elements.RTL.JsonObject)); public; default;


		[&Sequence]
		method GetSequence: sequence of Root_Items_ArrayItem; public;
		begin
			exit self.fNode.Select((n) -> begin
				exit new Root_Items_ArrayItem((n as RemObjects.Elements.RTL.JsonObject));
			end);
		end;

	end;

	Root_Numbers = public class
	private

		constructor(aNode: RemObjects.Elements.RTL.JsonArray); public;
		begin
			self.fNode := aNode;
		end;

		var fNode: RemObjects.Elements.RTL.JsonArray; private;

		property Count: Int64 read self.fNode.Count; public;


		property Items[aIndex: Int64]: Int64 read self.fNode[aIndex]:IntegerValue; public; default;


		[&Sequence]
		method GetSequence: sequence of Int64; public;
		begin
			exit self.fNode.Select((n) -> begin
				exit n.IntegerValue;
			end);
		end;

	end;

	Root_Nested_SubArray = public class
	private

		constructor(aNode: RemObjects.Elements.RTL.JsonArray); public;
		begin
			self.fNode := aNode;
		end;

		var fNode: RemObjects.Elements.RTL.JsonArray; private;

		property Count: Int64 read self.fNode.Count; public;


		property Items[aIndex: Int64]: Int64 read self.fNode[aIndex]:IntegerValue; public; default;


		[&Sequence]
		method GetSequence: sequence of Int64; public;
		begin
			exit self.fNode.Select((n) -> begin
				exit n.IntegerValue;
			end);
		end;

	end;

	Root_Nested = public class
	private

		constructor(aNode: RemObjects.Elements.RTL.JsonArray); public;
		begin
			self.fNode := aNode;
		end;

		var fNode: RemObjects.Elements.RTL.JsonArray; private;

		property Count: Int64 read self.fNode.Count; public;


		property Items[aIndex: Int64]: Root_Nested_SubArray read new Root_Nested_SubArray((self.fNode[aIndex] as RemObjects.Elements.RTL.JsonArray)); public; default;


		[&Sequence]
		method GetSequence: sequence of Root_Nested_SubArray; public;
		begin
			exit self.fNode.Select((n) -> begin
				exit new Root_Nested_SubArray((n as RemObjects.Elements.RTL.JsonArray));
			end);
		end;

	end;

	Root_Mixed = public class
	private

		constructor(aNode: RemObjects.Elements.RTL.JsonArray); public;
		begin
			self.fNode := aNode;
		end;

		var fNode: RemObjects.Elements.RTL.JsonArray; private;

		property Count: Int64 read self.fNode.Count; public;


		property Items[aIndex: Int64]: RemObjects.Elements.RTL.JsonNode read self.fNode[aIndex]; public; default;


		[&Sequence]
		method GetSequence: sequence of RemObjects.Elements.RTL.JsonNode; public;
		begin
			exit self.fNode;
		end;

	end;

end.