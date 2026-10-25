using Godot;
using Godot.Collections;
using System;
using System.IO;
using System.Text.Json;

public partial class JsonParser : Node
{
	public Dictionary? LoadAdofaiJson(string filePath)
	{
		if (!File.Exists(filePath))
		{
			GD.PrintErr("文件不存在: " + filePath);
			return null;
		}

		try
		{
			using var fs = File.OpenRead(filePath);
			var jsonDoc = JsonDocument.Parse(fs, new JsonDocumentOptions
			{
				AllowTrailingCommas = true,
				CommentHandling = JsonCommentHandling.Skip
			});

			Variant v = JsonElementToVariant(jsonDoc.RootElement);
			if (v.VariantType == Variant.Type.Dictionary)
			{
				jsonDoc.Dispose();
				return v.As<Dictionary>();
			}
			jsonDoc.Dispose();
			GD.PrintErr("根节点不是Dictionary");
			return new Dictionary();
		}
		catch (JsonException ex)
		{
			// JsonException 自带 LineNumber / BytePositionInLine
			GD.PrintErr($"JSON语法错误！行:{ex.LineNumber} 列:{ex.BytePositionInLine}");
			GD.PrintErr($"错误详情：{ex.Message}");
			return new Dictionary();
		}
		catch (Exception ex)
		{
			GD.PrintErr("解析JSON失败：", ex.Message);
			return new Dictionary();
		}
	}

	private Variant JsonElementToVariant(JsonElement elem)
	{
		switch (elem.ValueKind)
		{
			case JsonValueKind.Object:
				var dict = new Dictionary();
				foreach (var prop in elem.EnumerateObject())
				{
					dict[prop.Name] = JsonElementToVariant(prop.Value);
				}
				return dict;

			case JsonValueKind.Array:
				var arr = new Godot.Collections.Array();
				foreach (var item in elem.EnumerateArray())
				{
					arr.Add(JsonElementToVariant(item));
				}
				return arr;

			case JsonValueKind.String:
				return elem.GetString() ?? "";

			case JsonValueKind.Number:
				if (elem.TryGetInt64(out long l))
					return l;
				if (elem.TryGetDouble(out double d))
					return d;
				return 0;

			case JsonValueKind.True:
				return true;
			case JsonValueKind.False:
				return false;
			case JsonValueKind.Null:
				return default(Variant);
			default:
				return default(Variant);
		}
	}
}
