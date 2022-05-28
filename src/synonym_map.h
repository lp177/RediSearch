
#pragma once

#include "util/map.h"
#include "redismodule.h"
#include "util/arr.h"

#include <stdbool.h>

///////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Holding a term data
 *  term - the term itself
 *  ids - array of synonyms group ids that the term is belong to
 */

struct TermData {
  char* term;
  uint32_t* ids;

  TermData();
  TermData(RedisModuleIO* rdb);
  ~TermData();

  TermData* Copy();

  void RdbSave(RedisModuleIO* rdb);
  bool IdExists(uint32_t id);
  void AddId(uint32_t id);
};

// static const int SynMapKhid = 90;
// KHASH_MAP_INIT_INT64(SynMapKhid, TermData*);

// The synonym map data structure

struct SynonymMap : Object {
  uint32_t ref_count;
  uint32_t curr_id;
  UnorderedMap<uint64_t, TermData*> h_table;
  bool is_read_only;
  struct SynonymMap* read_only_copy;

  void ctor(bool is_read_only_);
  SynonymMap(bool is_read_only_) { ctor(is_read_only_); }
  SynonymMap(RedisModuleIO* rdb, int encver);

  ~SynonymMap();

  uint32_t GetMaxId();

  uint32_t Add(const char** synonyms, size_t size);
  uint32_t AddRedisStr(RedisModuleString** synonyms, size_t size);
  void Update(const char** synonyms, size_t size, uint32_t id);
  void UpdateRedisStr(RedisModuleString** synonyms, size_t size, uint32_t id);

  TermData* GetIdsBySynonym(const char* synonym, size_t len);
  TermData* GetIdsBySynonym(const char *synonym) { return GetIdsBySynonym(synonym, strlen(synonym)); }
  SynonymMap* GenerateReadOnlyCopy();
  void CopyEntry(uint64_t key, TermData* t_data);

  TermData** DumpAllTerms(size_t* size);

  size_t IdToStr(uint32_t id, char* buff, size_t len);
  SynonymMap* GetReadOnlyCopy(SynonymMap* smap);

  static void RdbSave(RedisModuleIO* rdb, void* value);

  static size_t IdToStr(uint32_t id, char* buff, size_t len);
  static const char** RedisStringArrToArr(RedisModuleString** synonyms, size_t size);
};

///////////////////////////////////////////////////////////////////////////////////////////////
