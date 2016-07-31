module makoto;

import std.conv: to;
import std.stdio;
import std.string: split, replace;
import std.regex;
import std.typecons: Tuple, tuple;
import std.c.windows.windows: HGLOBAL, GlobalFree;
import std.windows.charset;
import std.stdio;


alias Tuple!(Regex!char, "pattern",
             string, "toStr") ReplaceList;

alias Tuple!(string, "command",
             string, "charset",
             string, "str",
             string, "sender") Request;

string execute(string reqStr, ReplaceList ls[], string wd)
{
    foreach(ReplaceList reg; ls)
    {
        auto pat   = reg.pattern;
        string to_ = reg.toStr;
        reqStr     = reqStr.replace("hoge", to_);
    }

    return reqStr;
}

unittest {
    loadReplaceList("./");
    assert(execute("hogehogefoobar", replace_list) == "fugafugabarbar");
}

Request parseRequest (string input)
{
    auto command_regex   = regex(r"^(?P<command>EXECUTE|GET Version)");
    auto charset_regex   = regex(r"Charset: (?P<charset>.+)\r\n");
    auto string_regex    = regex(r"String: (?P<str>[^\r\n]+)");
    auto sender_regex    = regex(r"Sender: (?P<sender>.+)\r\n");

    string command = input.matchFirst(command_regex).captures["command"];
    string charset = input.matchFirst(charset_regex).captures["charset"];
    string str     = input.matchFirst(string_regex).captures["str"];
    string sender  = input.matchFirst(sender_regex).captures["sender"];

    return Request(command, charset, str, sender);
}

unittest {
    auto r = parseRequest("EXECUTE MAKOTO/2.0\r\n" ~
                          "Sender: embryo\r\n" ~
                          "Charset: Shift_JIS\r\n" ~
                          "String: Hello\r\n");
    assert(r.command == "EXECUTE");
    assert(r.sender == "embryo");
    assert(r.charset == "Shift_JIS");
    assert(r.str == "Hello");
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
    private string str;

    this(string str,
         string status="200 OK",
         string charset="Shift_JIS")
        {
            this.str = str;
            this.status = status;
            this.charset = charset;
        }

    override string toString()
        {
            string res;
            res = "MAKOTO/2.0 " ~ this.status;
            res ~= "\r\nCharset: " ~ this.charset;
            res ~= "\r\nString: " ~ this.str;
            res ~= "\r\n";
            return res;
        }
    unittest {
        auto res = new Response("hoge");
        auto res_str = to!string(res);
        assert(res_str == "MAKOTO/2.0 200 OK\r\nCharset: Shift_JIS\r\nString: hoge\r\n");
    }
}

ReplaceList[] loadReplaceList(string wd)
{
    auto f = File(wd~"shell-proxy-replace.txt", "r");
    ReplaceList ls[];
    foreach(l; f.byLine())
    {
        if (l == "") break;
        auto words = (to!string(l)).split(" ");
        auto t = ReplaceList(regex(words[0]), words[1]);

        ls ~= t;
    }
    return ls;
}
