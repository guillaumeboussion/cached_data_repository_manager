abstract class Filter {
  factory Filter.equals(String field, value) => FilterBase(field, value, FilterType.equals);

  /// Filter where the [field] value is not equals to the specified value.
  factory Filter.notEquals(String field, value) => FilterBase(field, value, FilterType.notEquals);

  /// Filter where the [field] value is not null.
  factory Filter.notNull(String field) => FilterBase(field, null, FilterType.notEquals);

  /// Filter where the [field] value is null.
  factory Filter.isNull(String field) => FilterBase(field, null, FilterType.equals);

  /// Filter where the [field] value is less than the specified [value].
  factory Filter.lessThan(String field, value) => FilterBase(field, value, FilterType.lessThan);

  /// Filter where the [field] value is less than or equals to the
  /// specified [value].
  factory Filter.lessThanOrEquals(String field, value) => FilterBase(field, value, FilterType.lessThanOrEquals);

  /// Filter where the [field] is greater than the specified [value]
  factory Filter.greaterThan(String field, value) => FilterBase(field, value, FilterType.greaterThan);

  /// Filter where the [field] is less than or equals to the specified [value]
  factory Filter.greaterThanOrEquals(String field, value) => FilterBase(field, value, FilterType.greaterThanOrEquals);

  /// Filter where the [field] is in the [list] of values
  factory Filter.inList(String field, List list) => FilterBase(field, list, FilterType.inList);

  /// Record must match any of the given [filters].
  ///
  /// If you only have two filters, you can also write `filter1 | filter2`.
  factory Filter.or(List<Filter> filters) => MultipleFilter.or(filters);

  /// Record must match all of the given [filters].
  ///
  /// If you only have two filters, you can also write `filter1 & filter2`.
  factory Filter.and(List<Filter> filters) => MultipleFilter.and(filters);

  /// Allow to add a new [Filter] to a current one.
  ///
  /// This function is mainly used to add a new [Filter] when a [Relation]
  /// is passed to the repository. Depending on the nature of the current [Filter]
  /// ([MultipleFilter] or [FilterBase]) it adds to the current
  static Filter addOrCreate({Filter? filterToAdd, Filter? currentFilter}) {
    if (currentFilter != null) {
      if (currentFilter is MultipleFilter && currentFilter.isAnd) {
        // Case of Filter.and, all filters are spreaded in one array cause every clause is needed
        return Filter.and([...currentFilter.filters, filterToAdd!]);
      } else {
        // Else, we have a new Filter.and condition including the new condition and the old one(s) (FilterBase or MultipleFilter as Filter.or)
        return Filter.and([currentFilter, filterToAdd!]);
      }
    } else {
      return filterToAdd!;
    }
  }

  // To override
  String get toGraphQLFilter;
}

class FilterType {
  /// Value to compare
  final int value;

  const FilterType._(this.value);

  /// equal filter
  static const FilterType equals = FilterType._(1);

  /// not equal filter
  static const FilterType notEquals = FilterType._(2);

  /// less then filter
  static const FilterType lessThan = FilterType._(3);

  /// less than or equals filter
  static const FilterType lessThanOrEquals = FilterType._(4);

  /// greater than filter
  static const FilterType greaterThan = FilterType._(5);

  /// greater than or equals filter
  static const FilterType greaterThanOrEquals = FilterType._(6);

  /// in list filter
  static const FilterType inList = FilterType._(7);

  /// matches filter
  static const FilterType matches = FilterType._(8);

  String toGraphQL() {
    switch (this) {
      case FilterType.equals:
        return 'EQ';
      case FilterType.notEquals:
        return 'NEQ';
      case FilterType.lessThan:
        return 'LT';
      case FilterType.lessThanOrEquals:
        return 'LTE';
      case FilterType.greaterThan:
        return 'GT';
      case FilterType.greaterThanOrEquals:
        return 'GTE';
      case FilterType.inList:
        return 'IN';
      case FilterType.matches:
        return 'LIKE';
      default:
        throw '${this} not supported';
    }
  }

  @override
  String toString() {
    switch (this) {
      case FilterType.equals:
        return '=';
      case FilterType.notEquals:
        return '!=';
      case FilterType.lessThan:
        return '<';
      case FilterType.lessThanOrEquals:
        return '<=';
      case FilterType.greaterThan:
        return '>';
      case FilterType.greaterThanOrEquals:
        return '>=';
      case FilterType.inList:
        return 'IN';
      case FilterType.matches:
        return 'MATCHES';
      default:
        throw '${this} not supported';
    }
  }
}

class FilterBase implements Filter {
  final dynamic _value;
  final String _field;
  final FilterType _filterType;

  String? get valueToGraphQL {
    if (_value is int || _value is double || _value is List) {
      if (_value is List<String>) {
        return listOfStringToGraphQLArg(_value);
      }
      return _value.toString();
    }

    if (_value is String) {
      return ("\"${_value.toString()}\"");
    }

    return null;

    // Else, if no correct argument has been provided
    // throw IncorrectFilterArgumentException(_field, _value);
  }

  /// Format a [List] of [String] to a GraphQL argument
  ///
  /// e.g : for a list ```["banana", "orange", "apple"]```, the basic [toString] method would output ```"[banana, orange, apple]"```
  ///
  /// Return this list as ```["banana", "orange", "apple"]```
  String listOfStringToGraphQLArg(List<String> list) {
    String formattedString = '[';

    for (int i = 0; i < list.length; i++) {
      formattedString += "\"${list[i]}\"";

      if (i != list.length - 1) {
        formattedString += ', ';
      }
    }

    return "$formattedString]";
  }

  @override
  String get toGraphQLFilter {
    return "{column: ${_field.toUpperCase()}, operator: ${_filterType.toGraphQL()}, value: ${valueToGraphQL.toString()} }";
  }

  FilterBase(this._field, this._value, this._filterType);
}

class MultipleFilter implements Filter {
  List<Filter> filters;

  bool isAnd;
  bool get isOr => !isAnd;

  MultipleFilter.and(this.filters) : isAnd = true;
  MultipleFilter.or(this.filters) : isAnd = false;

  @override
  String get toGraphQLFilter {
    String formattedFilters = '';

    for (int i = 0; i < filters.length; i++) {
      formattedFilters += filters[i].toGraphQLFilter;
      if (i != filters.length - 1) {
        formattedFilters += ', ';
      }
    }

    if (isAnd) {
      return "{ AND: [$formattedFilters]}";
    } else {
      return "{ OR: [$formattedFilters]}";
    }
  }
}

class SortOrder {
  final bool ascending;
  final String? column;
  final String? relationName;
  final String aggregateType;

  SortOrder({required this.column, this.ascending = true, required this.relationName, required this.aggregateType});

  Map<String, dynamic> get toJsonObject {
    Map<String, dynamic> json = {};
    if (relationName != null) {
      Map<String, dynamic> relationObj = {"aggregate": aggregateType.toUpperCase()};

      if (column != null) {
        relationObj["column"] = column!.toUpperCase();
      }

      json[relationName!] = relationObj;
      json["order"] = (ascending ? "ASC" : "DESC");
    } else {
      json["column"] = column!.toUpperCase();
      json["order"] = (ascending ? "ASC" : "DESC");
    }

    return json;
  }
}
