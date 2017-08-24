"use strict";

var parser = require ('./alfy.js').parser;
var fs = require ('fs');
var path = require ('path');

function preprocess (str)
{
	var variables = {};

	var source = [];

	var processed = [];
	var lines = str.split (/\r?\n/);
	var registerRegex = /\[register[ \t]+([A-Z-a-z\$\_][A-Za-z\$\_0-9]*)[ \t]+([^\]]*)\]/;
	var unregisterRegex = /\[unregister[ \t]+([A-Z-a-z\$\_][A-Za-z\$\_0-9]*)\]/;
	var ifRegex = /\[if[ \t]+([A-Z-a-z\$\_][A-Za-z\$\_0-9]*)[ \t]+((?:\=|\!\=))[ \t]+([^\]]*)\]/;
	var elseRegex = /\[else\]/;
	var endifRegex = /\[endif\]/;
	for (var i=0; i<lines.length; i++)
	{
		var line = lines[i];
		var regitem = line.match(registerRegex);
		var unregitem = line.match(unregisterRegex);
		var ifitem = line.match(ifRegex);
		var elseItem = line.match(elseRegex);
		var endifItem = line.match(endifRegex);
		if (regitem) 
		{
			if (source.length === 0 || source[source.length-1] === true) variables[regitem[1]] = regitem[2];
			processed.push ('');
		}
		else
		if (unregitem)
		{
			if (source.length === 0 || source[source.length-1] === true) delete variables[unregitem[1]];
			processed.push ('');
		}
		else 
		if (ifitem)  
		{
			// console.log (ifitem);
			var value;
			if (ifitem[2] === '=')
			{
				if (variables[ifitem[1]]===ifitem[3])
				{
					value = true;
				}
				else
				{
					value = false;
				}
			}
			else
			{
				if (variables[ifitem[1]]!==ifitem[3])
				{
					value = true;
				}
				else
				{
					value = false;
				}
			}

			
			if (source.length > 0) value = source[source.length-1] && value;
			source.push (value);
			processed.push ('');
		}
		else
		if (elseItem)
		{
			if (source.length > 0) source[source.length-1] = ! source[source.length-1];
			processed.push ('');
		}
		else
		if (endifItem)
		{
			if (source.length > 0) source.pop ();
			processed.push ('');
		}
		else
		{
			if (source.length === 0 || source[source.length-1] === true) 
			{
				var pline = '';

				for (var variable in variables)
				{
					var regex = new RegExp ('(^|[^\\w\\$])('+variable+')([^\\w\\$]|$)');
					line = line.replace (regex, function (s)
						{
							var sides = s.match (regex);
							return sides[1]+variables[variable]+sides[3];
						});
				}

				processed.push (line);
			}
			else
			{
				processed.push ('');
			}
		}
	}
	return processed.join ('\n');
}

var source = fs.readFileSync (process.argv[2]).toString ();

var preprocessed = preprocess (source);

// console.log (preprocessed);

var foutname = process.argv[3];
if (!foutname) foutname = process.argv[2]+'.json';

try
{
	var tree = parser.parse (preprocessed);
	fs.writeFileSync (foutname, JSON.stringify (tree, null, 2));
}
catch (e)
{
	// console.log (JSON.stringify(e, null, 4));
	var error = {};
	if (!e.hash.token)
	{
		error.error = 'lexical';
		error.line = (e.hash.line+1);
		error.text = e.message;
	}
	else
	{
		error.error = 'syntax';
		error.line = (e.hash.line+1);
		error.text = e.hash.text;
		error.token = e.hash.token;
		error.expected = e.hash.expected;
	}
	// console.log (JSON.stringify (error, null, 4));
	fs.writeFileSync (foutname, JSON.stringify (error, null, 2));
}
	
