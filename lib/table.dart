import 'dart:collection';

/// An Immutable data table that can be filled with varying data types.
class Table {
  final Map<String, List<dynamic>> _table = HashMap();
  List<String> _headers;

  /// Creates a table from a list of rows containing column values.
  Table.fromRows(List<List<dynamic>> rows) {
    _headers = rows[0].map((e) => e.toString()).toList();
    _table.addEntries(rows[0].map((header) => MapEntry(header.toString(), [])));

    final rowLength = rows[0].length;
    rows.skip(1).forEach((row) {
      if (row.length != rowLength) {
        throw FormatException('Row has invalid length: $row');
      }
      
      for (var col = 0; col < rowLength; col++) {
        _table[rows[0][col].toString()].add(row[col]);
      }
    });
  }

  /// Returns an umodifiable list containing headers for the table.
  /// 
  /// Maintains the order first supplied to the table.
  List<String> get headers => UnmodifiableListView(_headers);

  /// Returns the column associated with the case-sensitive [columnName] without the header.
  /// 
  /// Returns `null` if [columnName] isn't a header.
  List<dynamic> column(String columnName) {
    if (_table.containsKey(columnName)) {
      return List.unmodifiable(_table[columnName]);
    }

    return null;
  }

  /// Returns the row throughout the table, with the first non-header row counted as row 0.
  /// 
  /// Throws a range error if [rowNumber] is outside of bounds.
  List<dynamic> row(int rowNumber) {
    return _headers.map((header) => _table[header][rowNumber]).toList();
  }
}