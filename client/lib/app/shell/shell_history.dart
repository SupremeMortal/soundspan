// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The back and forward history of the shell's branches, for the top bar's
/// Back and Forward buttons (doc 09, Shell by Window Class).
///
/// Back pops the current branch; Forward re-opens the location most
/// recently popped in that branch, on top of the branch's detail stack
/// when the branch shows a detail. Each branch keeps its own forward list,
/// and any new navigation in a branch clears that branch's list.
class ShellHistory {
  final Map<int, String> _current = {};
  final Map<int, List<String>> _forward = {};
  final Set<int> _travelling = {};

  /// Records that [branch] shows [location].
  ///
  /// A location reached other than through [back] or [forward] clears the
  /// branch's forward list. Showing the current location again changes
  /// nothing.
  void visit(int branch, String location) {
    if (_current[branch] == location) return;
    _current[branch] = location;
    if (!_travelling.remove(branch)) _forward.remove(branch);
  }

  /// Whether [forward] has a location to re-open in [branch].
  bool canForward(int branch) => _forward[branch]?.isNotEmpty ?? false;

  /// Records that the current location of [branch] is about to be popped,
  /// so [forward] can re-open it.
  void back(int branch) {
    final current = _current[branch];
    if (current == null) return;
    (_forward[branch] ??= []).add(current);
    _travelling.add(branch);
  }

  /// Takes the location to re-open in [branch], or null when there is none.
  String? forward(int branch) {
    final list = _forward[branch];
    if (list == null || list.isEmpty) return null;
    _travelling.add(branch);
    return list.removeLast();
  }
}
