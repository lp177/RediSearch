/*
 * Copyright Redis Ltd. 2016 - present
 * Licensed under your choice of the Redis Source Available License 2.0 (RSALv2) or
 * the Server Side Public License v1 (SSPLv1).
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <math.h>

#include "../parse.h"
#include "parser.h"
#include "../../query_node.h"
#include "../../stopwords.h"

/* forward declarations of stuff generated by lemon */

#define RSQuery_Parse_v3 RSQueryParser_v3_ // weird Lemon quirk.. oh well..
#define RSQuery_ParseAlloc_v3 RSQueryParser_v3_Alloc
#define RSQuery_ParseFree_v3 RSQueryParser_v3_Free

void RSQuery_Parse_v3(void *yyp, int yymajor, QueryToken yyminor, QueryParseCtx *ctx);
void *RSQuery_ParseAlloc_v3(void *(*mallocProc)(size_t));
void RSQuery_ParseFree_v3(void *p, void (*freeProc)(void *));

%%{

machine query;

inf = ['+\-']? 'inf' $ 4;
size = digit+ $ 2;
number = '-'? digit+('.' digit+)? (('E'|'e') '-'? digit+)? $ 3;

quote = '"';
or = '|';
lp = '(';
rp = ')';
lb = '{';
rb = '}';
colon = ':';
semicolon = ';';
arrow = '=>';
minus = '-';
tilde = '~';
star = '*';
percent = '%';
rsqb = ']';
lsqb = '[';
escape = '\\';
squote = "'";
escaped_character = escape (punct | space | escape);
escaped_term = (((any - (punct | cntrl | space | escape)) | escaped_character) | '_')+ $0;

# these are the punctuations that are not valid in a tag, they have an especial
# meaning and need to be escaped to be considered as part of a tag
tag_invalid_punct = (rb | star | escape | '$');

token_separators = ( '!' | '"' | '#' | '$' | '%' | '&' | squote | '(' | ')' |
                    star |'+' | '-' | '.' | '/' | ':' | ';' | '<' | '=' | '>' |
                    '?' | '@' | '[' | escape | ']' | '^' | '`' | '{' | '}' |
                    '~' | '|' | ',' );
valid_punct =  token_separators - tag_invalid_punct;
invalid_punct = punct - valid_punct;

mod = '@'.escaped_term $ 1;
attr = '$'.escaped_term $ 1;
single_tag = ( (any - ( invalid_punct | tag_invalid_punct) ) | (escape (tag_invalid_punct)) | '_' )+ $2;

contains = (star.escaped_term.star | star.number.star | star.attr.star) $1;
prefix = (escaped_term.star | number.star | attr.star) $1;
suffix = (star.escaped_term | star.number | star.attr) $1;
as = 'AS'|'aS'|'As'|'as';
verbatim = squote . ((any - squote - escape) | escape.any)+ . squote $2;
wildcard = 'w' . verbatim $4;

assign_attr = arrow lb attr colon escaped_term rb $4;

contains_tag = colon lb star.single_tag.star :>> rb $1;
prefix_tag = colon lb single_tag.star :>> rb $1;
suffix_tag = colon lb star.single_tag :>> rb $1;
unescaped_tag = (colon lb single_tag :>> rb $1) 
              | (colon lb escape wildcard :>> rb $1) 
              | (colon lb escape 'w' single_tag :>> rb $1);
wildcard_tag = colon lb wildcard :>> rb $4;
wildcard_txt = colon lp wildcard :>> rp $4;

main := |*

  size => {
    tok.s = ts;
    tok.len = te-ts;
    char *ne = (char*)te;
    tok.numval = strtod(tok.s, &ne);
    tok.pos = ts-q->raw;
    RSQuery_Parse_v3(pParser, SIZE, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }
  };

  number => {
    tok.s = ts;
    tok.len = te-ts;
    char *ne = (char*)te;
    tok.numval = strtod(tok.s, &ne);
    tok.pos = ts-q->raw;
    RSQuery_Parse_v3(pParser, NUMBER, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }
  };

  mod => {
    tok.pos = ts-q->raw;
    tok.len = te - (ts + 1);
    tok.s = ts+1;
    RSQuery_Parse_v3(pParser, MODIFIER, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }
  };

  attr => {
    tok.pos = ts-q->raw;
    tok.len = te - (ts + 1);
    tok.s = ts+1;
    RSQuery_Parse_v3(pParser, ATTRIBUTE, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }
  };

  arrow => {
    tok.pos = ts-q->raw;
    tok.len = te - ts;
    tok.s = ts+1;
    RSQuery_Parse_v3(pParser, ARROW, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }
  };

  as => {
    tok.pos = ts-q->raw;
    tok.len = te - ts;
    tok.s = ts;
    RSQuery_Parse_v3(pParser, AS_T, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }
  };

  inf => {
    tok.pos = ts-q->raw;
    tok.s = ts;
    tok.len = te-ts;
    tok.numval = *ts == '-' ? -INFINITY : INFINITY;
    RSQuery_Parse_v3(pParser, NUMBER, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }
  };

  quote => {
    tok.pos = ts-q->raw;
    RSQuery_Parse_v3(pParser, QUOTE, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }
  };

  or => {
    tok.pos = ts-q->raw;
    RSQuery_Parse_v3(pParser, OR, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }
  };

  lp => {
    tok.pos = ts-q->raw;
    RSQuery_Parse_v3(pParser, LP, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }
  };

  rp => {
    tok.pos = ts-q->raw;
    RSQuery_Parse_v3(pParser, RP, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }
  };

  lb => {
    tok.pos = ts-q->raw;
    RSQuery_Parse_v3(pParser, LB, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }
  };

  rb => {
    tok.pos = ts-q->raw;
    RSQuery_Parse_v3(pParser, RB, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }
  };

  colon => {
    tok.pos = ts-q->raw;
    RSQuery_Parse_v3(pParser, COLON, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }
  };

  semicolon => {
    tok.pos = ts-q->raw;
    RSQuery_Parse_v3(pParser, SEMICOLON, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }
  };

  minus =>  {
    tok.pos = ts-q->raw;
    RSQuery_Parse_v3(pParser, MINUS, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }
  };

  tilde => {
    tok.pos = ts-q->raw;
    RSQuery_Parse_v3(pParser, TILDE, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }
  };

  star => {
    tok.pos = ts-q->raw;
    RSQuery_Parse_v3(pParser, STAR, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }
  };

   percent => {
    tok.pos = ts-q->raw;
    RSQuery_Parse_v3(pParser, PERCENT, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }
  };

  lsqb => {
    tok.pos = ts-q->raw;
    RSQuery_Parse_v3(pParser, LSQB, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }
  };

  rsqb => {
    tok.pos = ts-q->raw;
    RSQuery_Parse_v3(pParser, RSQB, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }
  };
  space;
  punct;
  cntrl;

  escaped_term => {
    tok.len = te-ts;
    tok.s = ts;
    tok.numval = 0;
    tok.pos = ts-q->raw;
    RSQuery_Parse_v3(pParser, TERM, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }
  };

  unescaped_tag => {
    tok.len = 1;
    tok.s = ts;
    RSQuery_Parse_v3(pParser, COLON, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }

    tok.len = 1;
    tok.s = ts + 1;
    tok.numval = 0;
    tok.pos = tok.s - q->raw;
    RSQuery_Parse_v3(pParser, LB, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }

    tok.len = te - (ts + 3);
    tok.s = ts + 2;
    tok.numval = 0;

    if(tok.s[0] == 'w' && tok.s[1] == '\'' && tok.s[tok.len-1] == '\'') {
      int is_attr = (*(ts + 4) == '$') ? 1 : 0;
      tok.type = is_attr ? QT_PARAM_WILDCARD : QT_WILDCARD;
      tok.len = te - (ts + 6 + is_attr);
      tok.s = ts + 4 + is_attr;
      tok.pos = tok.s - q->raw;
      RSQuery_Parse_v3(pParser, WILDCARD, tok, q);
    } else {
      tok.pos = tok.s - q->raw;
      tok.type = QT_TERM;
      RSQuery_Parse_v3(pParser, UNESCAPED_TAG, tok, q);
    }
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }

    tok.len = 1;
    tok.s = te - 1;
    tok.numval = 0;
    tok.pos = tok.s - q->raw;
    RSQuery_Parse_v3(pParser, RB, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }

  };

  wildcard_tag => {
    tok.len = 1;
    tok.s = ts;
    RSQuery_Parse_v3(pParser, COLON, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }

    tok.len = 1;
    tok.s = ts + 1;
    tok.numval = 0;
    tok.pos = tok.s - q->raw;
    RSQuery_Parse_v3(pParser, LB, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }

    tok.len = te - (ts + 3);
    tok.s = ts + 2;

    if(tok.s[0] == 'w' && tok.s[1] == '\'') {
      int is_attr = (*(ts + 4) == '$') ? 1 : 0;
      tok.type = is_attr ? QT_PARAM_WILDCARD : QT_WILDCARD;
      tok.len = te - (ts + 6 + is_attr);
      tok.s = ts + 4 + is_attr;
      tok.pos = tok.s - q->raw;
      tok.numval = 0;
      RSQuery_Parse_v3(pParser, WILDCARD, tok, q);
    } else {
      tok.len = te - (ts + 3);
      tok.s = ts + 2;
      tok.numval = 0;
      tok.pos = tok.s - q->raw;
      tok.type = QT_TERM;
      RSQuery_Parse_v3(pParser, UNESCAPED_TAG, tok, q);
    }
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }

    tok.len = 1;
    tok.s = te - 1;
    tok.numval = 0;
    tok.pos = tok.s - q->raw;
    RSQuery_Parse_v3(pParser, RB, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }

  };

  suffix_tag => {
    tok.len = 1;
    tok.s = ts;
    RSQuery_Parse_v3(pParser, COLON, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }

    tok.len = 1;
    tok.s = ts + 1;
    tok.numval = 0;
    tok.pos = tok.s - q->raw;
    RSQuery_Parse_v3(pParser, LB, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }

    int is_attr = (*(ts + 3) == '$') ? 1 : 0;
    tok.type = is_attr ? QT_PARAM_TERM : QT_TERM;
    tok.len = te - (ts + 3 + is_attr) - 1;
    tok.s = ts + 3 + is_attr;
    tok.numval = 0;
    tok.pos = tok.s - q->raw;
    RSQuery_Parse_v3(pParser, SUFFIX, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }

    tok.len = 1;
    tok.s = te - 1;
    tok.numval = 0;
    tok.pos = tok.s - q->raw;
    RSQuery_Parse_v3(pParser, RB, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }
  };

  prefix_tag => {
    tok.len = 1;
    tok.s = ts;
    RSQuery_Parse_v3(pParser, COLON, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }

    tok.len = 1;
    tok.s = ts + 1;
    tok.numval = 0;
    tok.pos = tok.s - q->raw;
    RSQuery_Parse_v3(pParser, LB, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }

    int is_attr = (*(ts + 2) == '$') ? 1 : 0;
    tok.type = is_attr ? QT_PARAM_TERM : QT_TERM;
    tok.len = te - (ts + 2 + is_attr) - 2;
    tok.s = ts + 2 + is_attr;
    tok.numval = 0;
    tok.pos = tok.s - q->raw;
    RSQuery_Parse_v3(pParser, PREFIX, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }

    tok.len = 1;
    tok.s = te - 1;
    tok.numval = 0;
    tok.pos = tok.s - q->raw;
    RSQuery_Parse_v3(pParser, RB, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }
  };

  contains_tag => {
    tok.len = 1;
    tok.s = ts;
    RSQuery_Parse_v3(pParser, COLON, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }

    tok.len = 1;
    tok.s = ts + 2;
    tok.numval = 0;
    tok.pos = tok.s - q->raw;
    RSQuery_Parse_v3(pParser, LB, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }

    int is_attr = (*(ts + 3) == '$') ? 1 : 0;
    tok.type = is_attr ? QT_PARAM_TERM : QT_TERM;
    tok.len = te - (ts + 3 + is_attr) - 2;
    tok.s = ts + 3 + is_attr;
    tok.numval = 0;
    tok.pos = tok.s - q->raw;
    RSQuery_Parse_v3(pParser, CONTAINS, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }

    tok.len = 1;
    tok.s = te - 1;
    tok.numval = 0;
    tok.pos = tok.s - q->raw;
    RSQuery_Parse_v3(pParser, RB, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }
  };

  prefix => {
    int is_attr = (*ts == '$') ? 1 : 0;
    tok.type = is_attr ? QT_PARAM_TERM : QT_TERM;
    tok.len = te - (ts + 1 + is_attr);
    tok.s = ts + is_attr;
    tok.numval = 0;
    tok.pos = ts-q->raw;
    RSQuery_Parse_v3(pParser, PREFIX, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }
  };

  suffix => {
    int is_attr = (*(ts+1) == '$') ? 1 : 0;
    tok.type = is_attr ? QT_PARAM_TERM : QT_TERM;
    tok.len = te - (ts + 1 + is_attr);
    tok.s = ts + 1 + is_attr;
    tok.numval = 0;
    tok.pos = ts-q->raw;
    RSQuery_Parse_v3(pParser, SUFFIX, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }
  };

  contains => {
    int is_attr = (*(ts+1) == '$') ? 1 : 0;
    tok.type = is_attr ? QT_PARAM_TERM : QT_TERM;
    tok.len = te - (ts + 2 + is_attr);
    tok.s = ts + 1 + is_attr;
    tok.numval = 0;
    tok.pos = ts-q->raw;
    RSQuery_Parse_v3(pParser, CONTAINS, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }
  };

  verbatim => {
    int is_attr = (*(ts+2) == '$') ? 1 : 0;
    tok.type = is_attr ? QT_PARAM_TERM : QT_TERM;
    tok.pos = ts-q->raw;
    tok.len = te - (ts + 2 + is_attr);
    tok.s = ts + 1 + is_attr;
    tok.numval = 0;
    RSQuery_Parse_v3(pParser, VERBATIM, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }
  };

  wildcard_txt => {
    tok.len = 1;
    tok.s = ts;
    RSQuery_Parse_v3(pParser, COLON, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }

    tok.len = 1;
    tok.s = ts + 1;
    tok.numval = 0;
    tok.pos = tok.s - q->raw;
    RSQuery_Parse_v3(pParser, LP, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }

    tok.len = te - (ts + 3);
    tok.s = ts + 2;
    
    int is_attr = (*(ts + 4) == '$') ? 1 : 0;
    tok.type = is_attr ? QT_PARAM_WILDCARD : QT_WILDCARD;
    tok.len = te - (ts + 6 + is_attr);
    tok.s = ts + 4 + is_attr;
    tok.pos = tok.s - q->raw;
    tok.numval = 0;
    RSQuery_Parse_v3(pParser, WILDCARD, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }

    tok.len = 1;
    tok.s = te - 1;
    tok.numval = 0;
    tok.pos = tok.s - q->raw;
    RSQuery_Parse_v3(pParser, RP, tok, q);
    if (!QPCTX_ISOK(q)) {
      fbreak;
    }

  };

*|;
}%%

%% write data;

QueryNode *RSQuery_ParseRaw_v3(QueryParseCtx *q) {
  void *pParser = RSQuery_ParseAlloc_v3(rm_malloc);

  int cs, act;
  const char* ts = q->raw;
  const char* te = q->raw + q->len;
  %% write init;
  QueryToken tok = {.len = 0, .pos = 0, .s = 0};

  //parseCtx ctx = {.root = NULL, .ok = 1, .errorMsg = NULL, .q = q};
  const char* p = q->raw;
  const char* pe = q->raw + q->len;
  const char* eof = pe;

  %% write exec;

  if (QPCTX_ISOK(q)) {
    RSQuery_Parse_v3(pParser, 0, tok, q);
  }
  RSQuery_ParseFree_v3(pParser, rm_free);
  if (!QPCTX_ISOK(q) && q->root) {
    QueryNode_Free(q->root);
    q->root = NULL;
  }
  return q->root;
}

