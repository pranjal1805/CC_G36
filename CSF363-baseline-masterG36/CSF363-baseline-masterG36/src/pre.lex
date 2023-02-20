/* just like Unix wc */
%option noyywrap
%option prefix="foo"
 
%x comment
%x comment2
%x DEFINE
%x DEFINE2
%x UNDEF
%x IFDEF
%x VALID
%x ENDIF
%x SKIP
 
%{
#include <string>
#include <unordered_map>
using namespace std;
 
string key;
unordered_map<string, string> map;
int flag=0;
%}
%%
 
"#def " {BEGIN(DEFINE); return 1;}
<DEFINE>[a-zA-Z]+ {key = yytext; map[key]="1"; return 1;}
<DEFINE>[\n]+ {BEGIN(INITIAL); return 1;}
<DEFINE>" " {BEGIN(DEFINE2); return 1;}
<DEFINE2>[^\\\n]+ {if(map[key] == "1") map[key] = ""; map[key] += yytext; return 5;}
<DEFINE2>"\\\n" {return 1;}
<DEFINE2>[\n]+ {BEGIN(INITIAL); return 1;}
 
"#undef " {BEGIN(UNDEF); return 2;}
<UNDEF>[a-zA-Z]+ {map.erase(yytext); return 2;}
<UNDEF>[ \n]+ {BEGIN(INITIAL); return 2;}
 
"#ifdef "   { flag=1;  BEGIN(IFDEF);  return 6;}
<IFDEF>[a-zA-Z0-9]+ {
    key= yytext;
    if(map.find(yytext) != map.end()) {
        flag=2;
        BEGIN(VALID);
    } else {
        BEGIN(ENDIF);
    }
    return 6;
}  
<IFDEF>[ \n]+ {BEGIN(INITIAL); return 6;}
<VALID>[ \n]+ {BEGIN(INITIAL);  return 6;}
<ENDIF>[^"#elif""endif"]* 
<ENDIF>"#elif "  {BEGIN(IFDEF); return 7;}
<ENDIF>"#endif " {BEGIN(INITIAL); return 7;}
 
"#endif"   {if(flag==0)    return 9;   flag=0;    BEGIN(INITIAL);}
 
"#elif"    {
    if(flag==0)    return 8;  
    if(flag==2){
        BEGIN(SKIP);    return 10;
    }        
    BEGIN(INITIAL);}

<SKIP>[^"endif"]*
<SKIP>"endif" {BEGIN(INITIAL);} 
 
"/*"         BEGIN(comment);
<comment>[^*]*        /* eat anything that's not a '*' */
<comment>"*"+[^*/]*   /* eat up '*'s not followed by '/'s */
<comment>"*"+"/"        {BEGIN(INITIAL);}
 
"//"    BEGIN(comment2);
<comment2>. /* om nom */
<comment2>[ \n]+ {BEGIN(INITIAL);}
 
[a-zA-Z]+ {return 3;}
. {return 4;}
%%
