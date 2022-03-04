// NP Sync
// Licensed under GPLv3.0

import std.array;
import std.datetime.systime;
import std.file;
import std.format;
import std.path;
import std.string: strip;
import std.stdio;


struct ContentEstimate {
	enum CONTENT_SIZE = 8;
	ulong size;
	SysTime modifiedTime;
	ubyte[CONTENT_SIZE] contentStart;

	this(ulong p_size, SysTime p_time, ubyte[CONTENT_SIZE] p_content) {
		size = p_size;
		modifiedTime = p_time;
		contentStart = p_content;
	}
}

struct DiskData {
	ContentEstimate[string] content;
	string[ContentEstimate] paths;
	string basePath;
}


void main()
{
	version(Windows) {
		writeln("NP Sync [Windows]");
	}
	else {
		writeln("ERROR: OS not yet supported");
		return;
	}

	string disk1 = getDisk("Primary Drive: ");
	if(disk1 == "") {
		writeln("Exiting..");
		return;
	}
	string disk2 = getDisk("Replica Drive: ");
	if(disk2 == "") {
		writeln("Exiting..");
		return;
	}
	
	File dup1 = File("dup_primary.tsv", "w");
	DiskData primaryData = getFileData(disk1, dup1);

	writefln("Disk read: %d files", primaryData.paths.length);

	File dup2 = File("dup_replica.tsv", "w");
	DiskData replicaData = getFileData(disk2, dup2);

	writefln("Replica read: %d files", replicaData.paths.length);

	File mismatch = File("mismatch.tsv", "w");
	File missing = File("missing.tsv", "w");
	compareDisks(primaryData, replicaData, mismatch, missing);

}

string getDisk(string prompt) {
	string basePath;

	write(prompt);
	string drive = readln().strip();

	version(Windows) {
		basePath = format("%s:\\", drive);
	}
	else {
		basePath = drive;
	}

	if(!basePath.exists()) {
		writefln("ERROR: invalid path '%s'", basePath);
		return "";
	}
	else if(!basePath.isDir()) {
		writefln("ERROR: '%s' is not a directory", basePath);
		return "";
	}
	else{
		writefln("Reading '%s'", basePath);
	}
	return basePath;
}

DiskData getFileData(string basePath, ref File duplicates) {
	DiskData data;
	data.basePath = basePath;
	ulong file_counter = 0;
	foreach(string subPath; basePath.dirEntries(SpanMode.depth, false)) {
		file_counter ++;
		try {
			if(subPath.isFile()) {
				string strippedPath = subPath.stripDrive();
				if(strippedPath in data.content) {
					writefln("\nBUG: Repeated file: '%s'", strippedPath);
					continue;
				}

				ulong size = subPath.getSize();
				ubyte[] dynContent = cast(ubyte[])subPath.read(ContentEstimate.CONTENT_SIZE);
				ubyte[8] content;
				content[0..dynContent.length] = dynContent;
				ContentEstimate est = ContentEstimate(size, subPath.timeLastModified(), content);
				if(est in data.paths) {
					duplicates.writefln("%s\t%s", strippedPath, data.paths[est]);
				}
				else {
					data.content[strippedPath] = est;
				}
				data.paths[est] = strippedPath;
			}
		}
		catch(FileException ex) {
			writefln("\nError with '%s': %s", subPath, ex.message);
		}
		if(!(file_counter & 255)) {
			writef("\r%d files", file_counter);
		}
	}
	writeln("\n Read complete.");
	return data;
}

void compareDisks(DiskData primary, DiskData replica, ref File mismatches, ref File missing) {
	foreach(path; primary.content.byKey()) {
		if(!(path in replica.content)) {
			string match = "<no match>";
			if(primary.content[path] in replica.paths){
				match = replica.paths[primary.content[path]];
			}
			missing.writefln("%s\t%s\t%s", replica.basePath, path, match);
		}
		else {
			ContentEstimate data1 = primary.content[path];
			ContentEstimate data2 = replica.content[path];
			if(data1 != data2) {
				bool preferPrimary = true;
				string reason = "default";
				if(data1.modifiedTime > data2.modifiedTime) {
					preferPrimary = true;
					reason = "date";
				}
				else if(data1.modifiedTime < data2.modifiedTime) {
					preferPrimary = false;
					reason = "date";
				}
				else if(data1.size > data2.size) {
					preferPrimary = true;
					reason = "size";
				}
				else if(data1.size < data2.size) {
					preferPrimary = false;
					reason = "size";
				}

				mismatches.writefln("%s\t%s\t%s", path, preferPrimary? primary.basePath : replica.basePath, reason );
			}
		}
	}
}