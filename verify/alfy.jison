%lex

%%

\"((\\.)|[^\"])*\"						return 'STRING_VALUE';

\s+								/* skip whitespace */
\{[^\{]*\}							/* skip comment */

if 								return 'IF';
else 							return 'ELSE';
while 							return 'WHILE';
repeat 							return 'REPEAT';
begin 							return 'BEGIN';
end 							return 'END';
with 							return 'WITH';
aslongas 						return 'ASLONGAS';
as 								return 'AS';
is 								return 'IS';
for 							return 'FOR';
run 							return 'RUN';
from 							return 'FROM';
to 								return 'TO';
downto		 					return 'DOWNTO';
of 								return 'OF';
element 						return 'ELEMENT';
step 							return 'STEP';
then 							return 'THEN';
array 							return 'ARRAY';
use 							return 'USE';
empty 							return 'EMPTY';
int 							return 'INT';
symbol 							return 'SYMBOL';
string 							return 'STRING';
real 							return 'REAL';
parameters 						return 'PARAMETERS';
value 							return 'VALUE';
struct 							return 'STRUCT';
define 							return 'DEFINE';
(valueof)|(do) 						return 'VALUE_OF';
label							return 'label';
string 							return 'STRING';
logic 							return 'LOGIC';
true 							return 'TRUE';
false 							return 'FALSE';
'=>'							return 'OF_TYPE';
'and'							return 'AND';
'or'							return 'OR';
'xor'							return 'XOR';
'not'							return 'NOT';
'mod'							return 'MOD';


[A-Za-z_\$][A-Za-z\$0-9_]*		return 'IDENTIFIER';

[0-9]+\.[0-9]*					return 'FLOAT_NUMBER';

[0-9]+							return 'INTEGER_NUMBER';


'+'								return '+';
'-'								return '-';
'*'								return '*';
'/'								return '/';
','								return ',';
'('								return '(';
')'								return ')';
';'								return ';';
'.'								return '.';

'='								return '=';
'!='							return '!=';

'|'								return '|';
'<='|'>='|'<'|'>'				return 'INEQUALITY';
<<EOF>>							return 'EOF';

/lex

%left AND 
%left OR XOR
%left '=' '!='
%left INEQUALITY
%right NOT
%left '+' '-'
%left '*' '/' MOD

%{
	var util = require ('util');
%}


%%

start: statements EOF
			{
				$$ = {
					type: 'script',
					statements: $1,
					line: yylineno+1
				};
				return $$;
			};

variable_definition: 		DEFINE variables
						{
							$$ = {
								type: 'define',
								elements: $2,
								line: yylineno+1
							};
						};

variables:	variable variables 
				{
					$2.splice (0, 0, $1);
					$$ = $2;
				}
			| variable
				{
					$$ = [$1];
				};

variable:		IDENTIFIER OF_TYPE data_type 
							{
								$$ = {
									id: $1,
									type: $3,
									line: yylineno+1
								};
							}
				|	IDENTIFIER OF_TYPE data_type  IS expression
							{
								$$ = {
									id: $1,
									type: $3,
									value: $5,
									line: yylineno+1
								};
							}
				|	IDENTIFIER IS expression
							{
								$$ = {
									id: $1,
									type: '',
									value: $3,
									line: yylineno+1
								};
							}
				|	IDENTIFIER OF_TYPE date_type run_parameters
							{
								$$ = {
									id: $1,
									type: $3,
									values: $5,
									line: yylineno+1
								};
							};

function_definition:		DEFINE IDENTIFIER parameters AS statement_posibilities
			{
				if (!util.isArray ($5)) $5 = [$5];
				$$ = {
					type: 'define_function',
					id: $2,
					parameters: $3,
					value_type: 'empty',
					statements: $5,
					line: yylineno+1
				};
			};

function_definition:		DEFINE IDENTIFIER parameters VALUE data_type AS statement_posibilities
			{
				if (!util.isArray ($7)) $7 = [$7];
				$$ = {
					type: 'define_function',
					id: $2,
					parameters: $3,
					value_type: $5,
					statements: $7,
					line: yylineno+1
				};
			};

parameters:		'|' variables
					{
						$$ = $2;
					}
				|'|' 
					{
						$$ = [];
					};

function_run:	VALUE_OF function_name run_parameters
			{
				$$ = {
					type: 'valueof',
					function: $2,
					parameters: $3,
					line: yylineno+1
				};
			};

function_name:	IDENTIFIER '.' function_name
							{
								$3.library.splice (0, 0, $1);
								$$ = $3;
							}
				| IDENTIFIER
							{
								$$ = 
								{
									id: $1,
									library: []
								};
							};

run_parameters:	WITH run_parameters_list PARAMETERS
			{
				$$ = $2;
			}
				| 
				{
					$$ = {}
				};

run_parameters_list:		IDENTIFIER IS expression run_parameters_list
										{
											$4[$1] = $3;
											$$ = $4;
										}
						|	IDENTIFIER IS expression
										{
											$$ = {};
											$$[$1] = $3;
										};

for:	FOR IDENTIFIER FROM expression direction expression STEP expression RUN statements END
				{
					$$ = {
						type: 'for',
					 	variable: $2,
					 	from: $4,
					 	direction: $5,
					 	to: $6,
					 	step: $8,
					 	statements: $10,
					 	line: yylineno+1
					};
				};

direction:   TO 
			| DOWNTO;

while:	WHILE expression RUN statements END
				{
					$$ = {
						type: 'while',
						expression: $2,
						statements: $4,
						line: yylineno+1
					};
				};

repeat:	REPEAT statements ASLONGAS expression
				{
					if (!util.isArray ($2)) $2=[$2];
					$$ = {
						type: 'repeat',
						expression: $4,
						statements: $2,
						line: yylineno+1
					};
				};

if:		IF expression THEN statements END
				{
					$$ = {
						type: 'if',
						expression: $2,
						then: $4,
						line: yylineno+1
					};
				}
	|	IF expression THEN statements ELSE statements END
				{
					$$ = {
						type: 'if',
						expression: $2,
						then: $4,
						else: $6,
						line: yylineno+1
					};
				};

data_type:		IDENTIFIER
			|	INT
			|	REAL
			|   SYMBOL
			|	STRING
			|	LOGIC
			|	EMPTY;

array: ARRAY IDENTIFIER OF data_type FROM INTEGER_NUMBER TO INTEGER_NUMBER
							{
								$$ = {
									type: 'array',
									id: $2,
									elements_type: $4,
									from: parseInt ($6),
									to: parseInt ($8),
									line: yylineno+1
								};
							};

struct:	STRUCT IDENTIFIER struct_elements END
					{
						$$ = {
							type: 'struct',
							id: $2,
							elements: $3,
							line: yylineno+1
						};
					};

struct_elements:	variable_definition ',' struct_elements 
										{
											// console.log ($3);
											$1.elements.forEach (function (element)
											{
												$3.splice (0, 0, element);
											});
											$$ = $3;
										}
				|	variable_definition
										{
											$$ = $1.elements;
										}
				|	
										{
											$$ = [];
										};

left_assignment:		IDENTIFIER
								{
									$$ = {
										type: 'id',
										value: $1,
										line: yylineno+1
									};
								}
					|	element_of_array
					|	element_of_struct;

element_of_struct:		 left_assignment ELEMENT IDENTIFIER
								{
									$$ = {
										type: 'element_of_struct',
										struct: $1,
										element: $3,
										line: yylineno+1
									};
								};

element_of_array:		left_assignment '(' expression ')'
								{
									$$ = {
										type: 'element_of_array',
										array: $1,
										index: $3,
										line: yylineno+1
									};
								};

attribution:	left_assignment IS expression
						{
							$$ = {
								type: 'attribution',
								to: $1, 
								from: $3,
								line: yylineno+1
							};
						};

expression:		expression '+' expression
						{
							$$ = {
								type: 'expression',
								op: '+',
								left: $1,
								right: $3,
								line: yylineno+1
							};
						}
			|	expression '-' expression
						{
							$$ = {
								type: 'expression',
								op: '-',
								left: $1,
								right: $3,
								line: yylineno+1
							};
						}
			|	expression '*' expression
						{
							$$ = {
								type: 'expression',
								op: '*',
								left: $1,
								right: $3,
								line: yylineno+1
							};
						}
			|	expression '/' expression
						{
							$$ = {
								type: 'expression',
								op: '/',
								left: $1,
								right: $3,
								line: yylineno+1
							};
						}
			|	left_assignment
						{
							$$ = $1;
						}
			|	'(' expression ')'
						{
							$$ = $2;
						}
			| 	expression MOD expression
						{
							$$ = {
								type: 'expression',
								op: 'mod',
								left: $1,
								right: $3,
								line: yylineno+1
							};
						}
			|	INTEGER_NUMBER
						{
							$$ = {
								type: 'value',
								t: 'int',
								value: parseInt ($1),
								line: yylineno+1
							};
						}
			|	FLOAT_NUMBER
						{
							$$ = {
								type: 'value',
								t: 'real',
								value: parseFloat ($1),
								line: yylineno+1
							};
						}
			|	STRING_VALUE
						{
							var value = $1.substring (1, $1.length-1);
							// console.log (value);
							value = value.replace (/\\n/, '\n');
							// console.log (value);
							value = value.replace (/\\r/, '\r');
							// console.log (value);
							value = value.replace (/\\"/, '"');
							// console.log (value);
							value = value.replace (/\\\\/, '\\');
							// console.log (value);
							var t = 'string';
							if (value.length === 1) t = 'symbol';
							$$ = {
								type: 'value',
								t: t,
								value: value,
								line: yylineno+1
							};
						}
			|	FALSE
						{
							$$ = {
								type: 'value',
								t: 'logic',
								value: false,
								line: yylineno+1
							};
						}
			|	TRUE
						{
							$$ = {
								type: 'value',
								t: 'logic',
								value: true,
								line: yylineno+1
							};
						}
			|	EMPTY
						{
							$$ = {
								type: 'value',
								t: 'empty',
								line: yylineno+1
							};
						}

			|	function_run
						{
							$$ = $1;
						}
			|	NOT expression
						{
							$$ = {
								type: 'expression',
								op: 'not',
								value: $2,
								line: yylineno+1
							};
						} 
			|
				'-' expression
						{
							$$ = {
								type: 'expression',
								op: '-',
								value: $2,
								line: yylineno+1
							};
						} 	
			|	expression AND expression
						{
							$$ = {
								type: 'expression',
								op: 'AND',
								left: $1,
								right: $3,
								line: yylineno+1
							};
						}
			|	expression OR expression
						{
							$$ = {
								type: 'expression',
								op: 'OR',
								left: $1,
								right: $3,
								line: yylineno+1
							};
						}
			|	expression XOR expression
						{
							$$ = {
								type: 'expression',
								op: 'XOR',
								left: $1,
								right: $3,
								line: yylineno+1
							};
						}
			|	expression '=' expression
						{
							$$ = {
								type: 'expression',
								op: '=',
								left: $1,
								right: $3,
								line: yylineno+1
							};
						}
			|	expression '!=' expression
						{
							$$ = {
								type: 'expression',
								op: '!=',
								left: $1,
								right: $3,
								line: yylineno+1
							};
						}
			|	expression INEQUALITY expression
						{
							$$ = {
								type: 'expression',
								op: $2,
								left: $1,
								right: $3,
								line: yylineno+1
							};
						};

statement:	statement_posibilities ';';

use:		USE STRING AS IDENTIFIER
						{
							$$ = {
								type: 'script',
								name: $2,
								variable: $4,
								line: yylineno+1
							};
						};

statement_posibilities:		expression
							|	attribution
							|	variable_definition
							|	function_definition
							|	array
							|	use
							|	struct
							|	if
							|	for
							|	while
							|	repeat
							|	VALUE expression
										{
											$$ = {
												type: 'value_of_function',
												value: $2,
												line: yylineno+1
											};
										}
							|	BEGIN statements END
										{
											$$ = $2
										}
							| {
								 $$ = {
								 	type: 'empty',
								 	line: yylineno+1
								 };
							  };


statements:		statement statements
					{
						$2.splice (0, 0, $1);
						$$ = $2;
					}
			|	statement
					{
						$$ = [$1];
					};

