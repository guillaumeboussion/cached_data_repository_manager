/// Decides how data should be fetched.
///
/// See each option to decide which one is the most appropriate
enum RepositoryPolicy {
  /// Return result from cache. Only fetch from network if cached result is not available or not up to date.
  /// Once data is fetched from Network, update data to cache then
  cacheFirst,

  /// Return result from newtork only. If it fails, will return null data, otherwise, will save to cache.
  /// This is useful when to want to have up to date data and then use it in the app with caching.
  networkOnly,

  /// Return result from network, fail if network call doesn't succeed, don't save to cache.
  noCache,

  /// Return result from network, then look into cache, and fail if none of both succeed.
  /// Save to cache if Network request succeed.
  networkFirst,
}

bool shouldFirstFetchInCache(RepositoryPolicy fetchPolicy) => fetchPolicy == RepositoryPolicy.cacheFirst;

bool willUpdateCache(RepositoryPolicy fetchPolicy) =>
    fetchPolicy == RepositoryPolicy.cacheFirst || fetchPolicy == RepositoryPolicy.networkFirst;

bool willExecuteOnCacheIfNetworkFails(RepositoryPolicy policy) {
  switch (policy) {
    case RepositoryPolicy.noCache:
    case RepositoryPolicy.cacheFirst:
      return false;
    case RepositoryPolicy.networkFirst:
    default:
      return true;
  }
}

/// Returns true if [RepositoryPolicy] or cache query result require to fetch data from server
bool shouldFetchNetwork(bool cacheQueryFailed, RepositoryPolicy policy) {
  return [RepositoryPolicy.noCache, RepositoryPolicy.networkFirst, RepositoryPolicy.networkOnly].contains(policy) ||
      (policy == RepositoryPolicy.cacheFirst && cacheQueryFailed);
}

/// Returns true if [RepositoryPolicy] allows data to be saved to internal cache.
bool shouldSaveToCache(RepositoryPolicy policy) {
  return policy != RepositoryPolicy.noCache;
}
