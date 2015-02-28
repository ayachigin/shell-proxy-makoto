module saori;

import std.conv: to;
import std.stdio;
import std.regex;
import std.typecons: Tuple;
import std.c.windows.windows: HGLOBAL, GlobalFree;
import std.windows.charset;

alias Tuple!(string, "charset",
             string, "command",
             string, "sender",
             string[], "arguments") Request;

Request parseRequest(string input)
{
	auto charset_regex   = regex(r"Charset: (?P<charset>.+)\r\n");
	auto command_regex   = regex(r"^(?P<command>EXECUTE|GET Version)");
	auto sender_regex    = regex(r"Sender: (?P<sender>.+)\r\n");
	auto arguments_regex = regex(r"Argument(?P<i>[0-9]+): (?P<argument>[^\r\n]+)", "m");
	
	string charset = input.matchFirst(charset_regex).captures["charset"];
	string command = input.matchFirst(command_regex).captures["command"];
	string sender  = input.matchFirst(sender_regex).captures["sender"];
	string[] arguments;
	foreach(m; input.matchAll(arguments_regex))
	{
		arguments ~= m.captures["argument"];
	}
	return Request(charset, command, sender, arguments);
}
unittest {
	auto r = parseRequest("EXECUTE SAORI/1.0\r\n" ~
	                      "Sender: SATORI\r\n" ~
	                      "Charset: Shift_JIS\r\n" ~
	                      "Argument0: Hello\r\nArgument1: World\r\n");
	assert(r.command == "EXECUTE");
	assert(r.sender == "SATORI");
	assert(r.charset == "Shift_JIS");
	assert(r.arguments.length == 2);
	assert(r.arguments[0] == "Hello");
	assert(r.arguments[1] == "World");
}

string fromMBS(HGLOBAL h)
{
	auto s = fromMBSz(cast (immutable(char)*) to!string(cast (char*) h));
	GlobalFree(h);
	return s;
}

class Response
{
	private string status;
	private string charset;
	private string[] values;

	this(string[] values,
		 string status="200 OK",
	     string charset="Shift_JIS")
	{
		this.values = values;
		this.status = status;
		this.charset = charset;
	}

	string toResponseString()
	{
		string res;
		res = "SAORI/1.0 " ~ this.status;
		res ~= "\r\nCharset: " ~ this.charset;
		if (this.values)
		{
			res ~= "\r\nResult: " ~ this.values[0];
			res ~= "\r\nValue0: " ~ this.values[0];
			if (this.values.length >= 2)
			{
				foreach(i, val; this.values[1..$])
				{
					res ~= "\r\nValue" ~ to!string(i+1) ~ ": " ~ val;
				}
			}
		}
		res ~= "\r\n\r\n";
		return res;
	}
	unittest {
		auto res = new Response(["hoge", "fuga"]);
		auto res_str = res.toResponseString;
		assert(res_str == "SAORI/1.0 200 OK\r\nResult: hoge\r\nValue0: hoge\r\nValue1: fuga\r\nCharset: Shift_JIS");
	}
}

