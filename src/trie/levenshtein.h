#pragma once

#include "rune_util.h"
#include "sparse_vector.h"
#include "rmutil/vector.h"

#include <stdlib.h>

///////////////////////////////////////////////////////////////////////////////////////////////

struct DFANode;
struct DFAEdge;

//---------------------------------------------------------------------------------------------

/*
* SparseAutomaton is a C implementation of a levenshtein automaton using
* sparse vectors, as described and implemented here:
* http://julesjacobs.github.io/2015/06/17/disqus-levenshtein-simple-and-fast.html
*
* We then convert the automaton to a simple DFA that is faster to evaluate during the query stage.
* This DFA is used while traversing a Trie to decide where to stop.
*/

struct SparseAutomaton : Object {
  const Runes &runes; //@@ ownership
  int max;

  SparseAutomaton(const Runes &runes, int maxEdits) : runes(runes),max(maxEdits) {}

  SparseVector Start();
  SparseVector Step(SparseVector &state, rune c);

  bool IsMatch(const SparseVector &v) const;
  bool CanMatch(const SparseVector &v) const;
};

//---------------------------------------------------------------------------------------------

// DFAFilter is a constructed DFA used to filter the traversal on the trie

struct DFACache : Vector<std::unique_ptr<DFANode>> {
  typedef Vector<std::unique_ptr<DFANode>> Super;

  DFANode *find(const SparseVector &v) const;
  void put(DFANode *node);
};

//---------------------------------------------------------------------------------------------

struct DFAEdge : Object {
  DFAEdge(DFANode *n, rune r) : n(n), r(r) {}
  DFANode *n;
  rune r;
};

//---------------------------------------------------------------------------------------------

// DFANode is DFA graph node constructed using the Levenshtein automaton

struct DFANode : Object {
  int distance;
  int match;
  SparseVector v;
  Vector<DFAEdge> edges;
  struct DFANode *fallback;

  DFANode(int distance, SparseVector &&state);

  void build(SparseAutomaton &a, DFACache &cache);
  DFANode *getCache(const SparseVector &v) const;

  DFANode *getEdgeNode(rune r);
  void addEdge(rune r, DFANode *child);
};

//---------------------------------------------------------------------------------------------

enum FilterCode { F_CONTINUE = 0, F_STOP = 1 };

struct DFAFilter : Object {
	DFAFilter(Runes &runes, int maxDist, bool prefixMode);

  DFACache cache; // cache of DFA states, allowing re-use of states
  Vector<DFANode*> stack; // stack of states leading up to the current state. NOTE: null nodes are allowed.
  Vector<int> distStack; // stack of minimal distance for each state, used for prefix matching

  bool prefixMode; // whether the filter works in prefix mode

  SparseAutomaton a;

  FilterCode Filter(rune b, int *matched, int *match);
  void StackPop(int numLevels);
};

///////////////////////////////////////////////////////////////////////////////////////////////
