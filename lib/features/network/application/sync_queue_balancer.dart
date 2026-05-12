class SyncQueueBalancer {
  int balance(int pendingItems, int onlinePeers) {
    if (onlinePeers <= 0) return pendingItems;
    return (pendingItems / onlinePeers).ceil();
  }
}
