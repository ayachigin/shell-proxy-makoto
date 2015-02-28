module dll_main;

import core.sys.windows.dll;
import std.conv;
import cstring = std.c.string;
import std.c.windows.windows;
import std.stdio;
import std.regex;
import std.typecons;
import std.windows.charset;

import saori: Request, Response, parseRequest, fromMBS;

// SAORIがロードされたときに渡されるパスをいれとく変数。
string working_directory;

// dll作るときの定型文
version(Windows) extern(Windows) bool DllMain(void* hInstance,
	                                          uint ulReason,
                                              void*)
{
	switch (ulReason)
	{
		default: assert(0);
		case DLL_PROCESS_ATTACH:
			dll_process_attach( hInstance, true );
			break;
			
		case DLL_PROCESS_DETACH:
			dll_process_detach( hInstance, true );
			break;
			
		case DLL_THREAD_ATTACH:
			dll_thread_attach( true, true );
			break;
			
		case DLL_THREAD_DETACH:
			unload();
			dll_thread_detach( true, true );
			break;
	}
	return true;
}


// exportする関数たち
extern(C) {
	export bool load(HGLOBAL h, long n)
	{
		auto input = to!string(cast(char*)h);
		working_directory = input;
		GlobalFree(h);
		return true;
	}
	
	export bool unload()
	{
		return true;
	}
	
	export HGLOBAL request(HGLOBAL h, long *n)
	{
		// 入力を受け取る
		//auto request = parseRequest(to!string(cast(char*)h));
		auto request = parseRequest(fromMBS(h));
		GlobalFree(h);
		string res;
		switch (request.command) {
			case "GET Version":
				res = new Response([]).toResponseString;
				break;
			case "EXECUTE":
				res = new Response(request.arguments).toResponseString;
				break;
			default:
				break;
		}

		auto len = res.length;
		h = LocalAlloc(0, len+1);
		cstring.memcpy(h, toMBSz(res), len+1);
		return h;
	}
}