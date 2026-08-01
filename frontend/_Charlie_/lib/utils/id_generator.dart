// Generates unique ids for budgets, budget items, and other locally
// created records.
//
// Plain `DateTime.now().millisecondsSinceEpoch` collides whenever several
// items are created back-to-back in the same loop iteration/tick - e.g.
// recycling a budget (looping over every item) or building a budget from
// a list of AI-suggested items. All of those items would end up with the
// *same* id.
//
// That collision was the root cause of old/recycled budgets loading with
// only one item (or none): budgets are saved to Firebase as a map keyed
// by item id (`itemsMap[item.id] = {...}`), so every item sharing an id
// overwrites the previous one - only the last one written survives.
//
// This combines the current timestamp with a monotonically increasing
// counter, so ids are guaranteed unique even when generated many times
// within the same millisecond.
class IdGenerator {
  static int _counter = 0;

  static String next() {
    _counter++;
    return "${DateTime.now().millisecondsSinceEpoch}_$_counter";
  }
}
