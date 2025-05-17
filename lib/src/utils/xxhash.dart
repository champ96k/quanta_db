class XXHash {
  XXHash._();
  static const int _prime1 = 2654435761;
  static const int _prime2 = 2246822519;
  static const int _prime3 = 3266489917;
  static const int _prime5 = 374761393;

  static int hash64(List<int> data) {
    if (data.isEmpty) return 0;

    var h1 = _prime1 + _prime5;
    var h2 = _prime2;

    var i = 0;
    while (i + 8 <= data.length) {
      h1 = _rotl64(h1 + _getInt64(data, i) * _prime2, 31) * _prime1;
      h2 = _rotl64(h2 + _getInt64(data, i + 4) * _prime2, 31) * _prime1;
      i += 8;
    }

    if (i + 4 <= data.length) {
      h1 = _rotl64(h1 + _getInt32(data, i) * _prime2, 31) * _prime1;
      i += 4;
    }

    while (i < data.length) {
      h1 = _rotl64(h1 + data[i] * _prime5, 11) * _prime1;
      i++;
    }

    h1 ^= h1 >> 33;
    h1 *= _prime2;
    h1 ^= h1 >> 29;
    h1 *= _prime3;
    h1 ^= h1 >> 32;

    return h1;
  }

  static int _getInt32(List<int> data, int offset) {
    if (offset + 3 >= data.length) {
      // Handle partial data at the end
      var result = 0;
      for (var i = 0; i < 4 && offset + i < data.length; i++) {
        result |= data[offset + i] << (24 - (i * 8));
      }
      return result;
    }

    return (data[offset] << 24) |
        (data[offset + 1] << 16) |
        (data[offset + 2] << 8) |
        data[offset + 3];
  }

  static int _getInt64(List<int> data, int offset) {
    if (offset + 7 >= data.length) {
      // Handle partial data at the end
      var result = 0;
      for (var i = 0; i < 8 && offset + i < data.length; i++) {
        result |= data[offset + i] << (56 - (i * 8));
      }
      return result;
    }

    return (_getInt32(data, offset) << 32) | _getInt32(data, offset + 4);
  }

  static int _rotl64(int x, int r) {
    return (x << r) | (x >>> (64 - r));
  }
}
