/* just like Unix wc */
%option noyywrap
%option prefix="foo"

%x comment
%x comment2
%x DEFINE
%x DEFINE2
%x UNDEF
%x IFDEF
%x ELIF
%x ELSE
%x ENDIF
%x SKIP

%{
#include <string>
#include<iostream>
#include <unordered_map>
#include<cstdio>
using namespace std;

string key;
unordered_map <string, string> map;
int flag=0, val=0;
%}
%%

"#def " {BEGIN(DEFINE); return 1;}
<DEFINE>[a-zA-Z][a-zA-Z0-9]* {key = yytext; map[key]="1"; return 1;}
<DEFINE>[\n]+ {BEGIN(INITIAL); return 1;}
<DEFINE>" " {BEGIN(DEFINE2); return 1;}
<DEFINE2>[^\\\n]+ {if(map[key] == "1") map[key] = ""; map[key] += yytext; return 5;}
<DEFINE2>"\\\n" {return 1;}
<DEFINE2>[\n]+ {BEGIN(INITIAL); return 1;}

"#undef " {BEGIN(UNDEF); return 2;}
<UNDEF>[a-zA-Z][a-zA-Z0-9]* {map.erase(yytext); return 2;}
<UNDEF>[ \n]+ {BEGIN(INITIAL); return 2;}


"#ifdef " {BEGIN(IFDEF); return 6;}
<IFDEF>[a-zA-Z][a-zA-Z0-9]* {
val=1;
key=yytext;
if(map.find(key) != map.end()) {
    flag=1;
} else {
    BEGIN(SKIP);
}
return 6;
}
<IFDEF>[ \n]+ {BEGIN(INITIAL); return 6;}


"#elif " {BEGIN(ELIF); return 6;}
<ELIF>[a-zA-Z][a-zA-Z0-9]* {
if(val==0){
    return 8;
}
key=yytext;
val=2;
if(map.find(key) != map.end() && flag==0) {
    flag=1;
} else {
    BEGIN(SKIP);
}
return 6;
}
<ELIF>[ \n]+ {BEGIN(INITIAL); return 6;}


"#else" {BEGIN(ELSE); return 6;}
<ELSE>[ \n]+ {
if(val==0 || val==1){
    return 11;
}
val=3;
if(flag==0) {
    flag=1;
    BEGIN(INITIAL);
} else {
    BEGIN(SKIP);
}
return 6;
}

"#endif" {BEGIN(ENDIF); return 6;}
<ENDIF>[ \n]+ {if(val==0){return 9;} flag=0; BEGIN(INITIAL); return 6;}

<SKIP>[^(?!.*(#elif|#else|#endif)).*$] {return 6;}
<SKIP>"#else" {BEGIN(ELSE); return 6;}
<SKIP>"#endif" {BEGIN(ENDIF); return 6;}
<SKIP>"#elif " {BEGIN(ELIF); return 6;}

"/*"         BEGIN(comment);
<comment>[^*]*        /* eat anything that's not a '*' */
<comment>"*"+[^*/]*   /* eat up '*'s not followed by '/'s */
<comment>"*"+"/"        {BEGIN(INITIAL);}

"//"    BEGIN(comment2);
<comment2>.
<comment2>[ \n]+ {BEGIN(INITIAL);}
[\n ] {return 4;}
[a-zA-Z][a-zA-Z0-9]* {return 3;}
. {return 4;}
%%
