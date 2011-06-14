var abs = func(n) { n < 0 ? -n : n }

var sgn = func(x) { x < 0 ? -1 : x > 0 }

var max = func(x) {
    var n = x;
    for (var i = 0; i < size(arg); i += 1) {
        if (arg[i] > n) n = arg[i];
    }
    return n;
}

var min = func(x) {
    var n = x;
    for (var i = 0; i < size(arg); i += 1) {
        if (arg[i] < n) n = arg[i];
    }
    return n;
}

var avg = func {
    var x = 0;
    for (var i = 0; i < size(arg); i += 1) {
        x += arg[i];
    }
    x /= size(arg);
    return x;
}

var pow = func(x, y) { exp(y * ln(x)) }

var mod = func(n, m) {
    var x = n - m * int(n/m);      # int() truncates to zero, not -Inf
    return x < 0 ? x + abs(m) : x; # ...so must handle negative n's
}

var asin = func(y) { atan2(y, sqrt(1-y*y)) }

var acos = func(x) { atan2(sqrt(1-x*x), x) }

var tan = func(x) { sin(x) / (cos(x) or die("tangens infinity")) }

var _iln10 = 1/ln(10);
var log10 = func(x) { ln(x) * _iln10 }
