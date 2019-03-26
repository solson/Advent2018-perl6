#!/usr/bin/env perl6

sub MAIN(Str $day, Str $part, Str $file = "input/$day") {
  my $input = slurp($file) or die "failed to read $file";
  say advent($day, $part, $input.chomp);
}

sub cycle($s) { |$s xx * }

multi advent('day01', '1', Str $in) {
  $in.lines.sum
}

multi advent('day01', '2', Str $in) {
  cycle($in.lines).produce(&[+]).repeated.first
}

multi advent('day02', '1', Str $in) {
  my @counts = $in.lines.map(*.comb.Bag.values.any);
  @counts.grep(2) * @counts.grep(3)
}

sub is-close(Str $a, Str $b) {
  ($a.comb Z!eq $b.comb).sum == 1
}

sub uncurry(&f) {
  -> ($a, $b) { f($a, $b) }
}

multi advent('day02', '2', Str $in) {
  my @ids = $in.lines;
  my ($a, $b) = (@ids X @ids).first(uncurry(&is-close));
  # for @ids X @ids -> ($a, $b) {
  ($a.comb Z $b.comb).grep(uncurry(&[eq])).map(*[0]).join
}

my regex claim {
  '#' $<id>=\d+ ' @ ' $<left>=\d+ ',' $<top>=\d+ ': ' $<width>=\d+ 'x' $<height>=\d+
}

multi advent('day03', '1', Str $in) {
  my @fabric[1000, 1000];
  my $count = 0;
  for $in.match(&claim, :global) -> $/ {
    for ($<left> ..^ $<left> + $<width>) X ($<top> ..^ $<top> + $<height>) -> ($i, $j) {
      $count++ if @fabric[$i; $j]++ == 1;
    }
  }
  $count
}

multi advent('day03', '2', Str $in) {
  my @fabric[1000, 1000];
  my %hit is SetHash;
  my %ids is SetHash;
  for $in.match(&claim, :global) -> $/ {
    my $id = +$<id>;
    %ids{$id}++;
    for ($<left> ..^ $<left> + $<width>) X ($<top> ..^ $<top> + $<height>) -> ($i, $j) {
      if @fabric[$i; $j] {
        %hit{@fabric[$i; $j]}++;
        %hit{$id}++;
      }
      @fabric[$i; $j] = $id;
    }
  }
  %ids (-) %hit
}

my regex guard_record {
  '[' $<date>=[ \d**4 '-' \d**2 '-' \d**2 ] ' ' $<hhmm>=[ \d**2 ':' \d**2 ] '] ' $<text>=.*
}

sub guard_sleeps(Str $in) {
  my %guard_sleep;
  my $guard;
  my $prev_date = DateTime.new(0);

  for $in.lines.sort {
    .match(&guard_record) or die;
    my $date = DateTime.new($<date> ~ 'T' ~ $<hhmm> ~ ':00Z');
    $date = $date.truncated-to('day').later(:1day) if $date.hour == 23;
    my $minutes = ($date - $prev_date) / 60;
    given $<text> {
      when /'Guard #' $<id>=\d+ ' begins shift'/ {
        $guard = +$<id>;
      }
      when 'wakes up' {
        %guard_sleep{$guard} //= [0 xx 60];
        %guard_sleep{$guard}[$_]++ for $prev_date.minute ..^ $date.minute;
      }
    }
    $prev_date = $date;
  }

  %guard_sleep
}

multi advent('day04', '1', Str $in) {
  my %guard_sleep = guard_sleeps($in);
  my $guard = %guard_sleep.max(*.value.sum).key;
  my $minute = %guard_sleep{$guard}.maxpairs.first.key;
  $guard * $minute
}

multi advent('day04', '2', Str $in) {
  my %guard_sleep = guard_sleeps($in);
  my ($guard, $minute) = %guard_sleep.kv.map(-> $guard, @minutes {
    my ($minute, $sleepiness) = @minutes.maxpairs.first.kv;
    ($guard, $minute) => $sleepiness
  }).max(*.value).key;
  $guard * $minute
}

sub parse-polymer(Str $in) {
  my %letter-to-val = |(('a'..'z') Z=> (1..26)), |(('A'..'Z') Z=> (-1,-2...-26));
  $in.chomp.comb.map(-> $x { %letter-to-val{$x} })
}

sub react(@polymer) {
  my @units = @polymer.clone;
  my $i = 0;
  while $i < @units - 1 {
    if @units[$i] == -@units[$i + 1] {
      @units.splice($i, 2);
      $i = max(0, $i - 1);
    } else {
      $i++;
    }
  }
  @units
}

multi advent('day05', '1', Str $in) {
  +react(parse-polymer($in))
}

multi advent('day05', '2', Str $in) {
  my @units = parse-polymer($in);
  (1..26).map(-> $unit { +react(@units.grep(*.abs != $unit.abs)) }).min
}

class Point {
  has Int $.x;
  has Int $.y;
}

sub point(@coords where 2 --> Point) {
  Point.new(x => +@coords[0], y => +@coords[1])
}

sub dist(Point $a, Point $b --> Int) {
  ($a.x - $b.x).abs + ($a.y - $b.y).abs
}

multi advent('day06', '1', Str $in) {
  my @points = $in.lines.map: { point(.split(', ')) };
  my $width = @points.map(*.x).max;
  my $height = @points.map(*.y).max;
  sub on-boundary(Point $p) { $p.x == 0 | $width || $p.y == 0 | $height }
  my @areas = [0 xx @points.elems];

  for (0..$width X 0..$height).map(&point) -> $p {
    my @closest = @points.map({ dist($p, $_) }).minpairs;
    if @closest.elems == 1 {
      my $closest = @closest.first.key;
      if on-boundary($p) {
        @areas[$closest] = Inf;
      } else {
        @areas[$closest]++;
      }
    }
  }

  @areas.grep(* != Inf).max
}

multi advent('day06', '2', Str $in) {
  my @points = $in.lines.map: { point(.split(', ')) };
  my $width = @points.map(*.x).max;
  my $height = @points.map(*.y).max;
  sub on-boundary(Point $p) { $p.x == 0 | $width || $p.y == 0 | $height }
  my $region-size = 0;

  for (0..$width X 0..$height).map(&point) -> $p {
    $region-size++ if @points.map({ dist($p, $_) }).sum < 10000;
  }

  $region-size
}

sub parse-prereqs(Str $in --> Hash[SetHash]) {
  my SetHash %prereqs;
  for $in.lines {
    m/'Step ' (\w) ' must be finished before step ' (\w) ' can begin.'/ or die;
    %prereqs{$0} //= SetHash.new;
    %prereqs{$1} //= SetHash.new;
    %prereqs{$1}{~$0}++;
  }
  %prereqs
}

multi advent('day07', '1', Str $in) {
  my SetHash %prereqs = parse-prereqs($in);
  my $order = "";
  while %prereqs {
    my $step = %prereqs.grep(!*.value).min.key;
    $order ~= $step;
    %prereqs{$step}:delete;
    $_{$step}-- for %prereqs.values;
  }
  $order
}

multi advent('day07', '2', Str $in) {
  my SetHash %prereqs = parse-prereqs($in);
  my $time = 0;
  my @queue;

  while %prereqs || @queue {
    my @available = %prereqs.grep(!*.value).map(*.key).sort;

    # Assign as many free workers to available tasks as possible.
    while @queue < 5 && @available {
      my $task = @available.shift;
      @queue.push: $task => $time + 60 + ($task.ord - 'A'.ord + 1);
      %prereqs{$task}:delete;
    }

    # Step forward in time and finish a task.
    @queue.=sort(*.value);
    (my $task, $time) = @queue.shift.kv;
    $_{$task}-- for %prereqs.values;
  }

  $time
}

class Tree {
  has Tree @.children;
  has Int @.metadata;

  method sum-metadata {
    @.metadata.sum + @.children.map(*.sum-metadata).sum
  }

  method value {
    if @.children {
      @.children[@.metadata.map(* - 1)].grep(*.defined).map(*.value).sum
    } else {
      @.metadata.sum
    }
  }

  method from-str(Str $in --> Tree) {
    Tree.from-array(Array[Int].new($in.split(' ').map(*.Int)))
  }

  method from-array(Int @data --> Tree) {
    my Int $num-children = @data.shift;
    my Int $num-metadata = @data.shift;
    Tree.new(
      children => [Tree.from-array(@data) for ^$num-children],
      metadata => @data.splice(0, $num-metadata),
    )
  }
}

multi advent('day08', '1', Str $in) {
  Tree.from-str($in).sum-metadata
}

multi advent('day08', '2', Str $in) {
  Tree.from-str($in).value
}

multi advent('day09', '1', Str $in) {
  do for $in.lines {
    m/(\d+) ' players; last marble is worth ' (\d+) ' points'/ or die;
    my Int $num-players = $0.Int;
    my Int $last-marble = $1.Int;
    my Int @scores = 0 xx $num-players;
    my int @marbles = [0];
    my int $i = 0;

    for 1..$last-marble*100 Z cycle(^$num-players) -> ($next-marble, $player) {
      if $next-marble %% 23 {
        $i = ($i - 7) % @marbles.elems;
        my $score = $next-marble + @marbles.splice($i, 1)[0];
        @scores[$player] += $score;
      } else {
        $i = ($i + 2) % @marbles.elems;
        $i = @marbles.elems if $i == 0;
        @marbles.splice($i, 0, $next-marble);
      }
    }

    @scores.max
  }
}

class Marble {
  has Marble $.prev is rw;
  has Marble $.next is rw;
  has int $.number;
}

multi advent('day09', '2', Str $in) {
  do for $in.lines {
    m/(\d+) ' players; last marble is worth ' (\d+) ' points'/ or die;
    my Int $num-players = $0.Int;
    my Int $last-marble = $1.Int;
    my Int @scores = 0 xx $num-players;
    my Marble $marble .= new(prev => Nil, next => Nil, number => 0);
    $marble.prev = $marble;
    $marble.next = $marble;

    for 1..$last-marble*100 Z cycle(^$num-players) -> ($next-marble, $player) {
      if $next-marble %% 23 {
        $marble.=prev for ^7;
        @scores[$player] += $next-marble + $marble.number;
        $marble.prev.next = $marble.next;
        $marble.next.prev = $marble.prev;
        $marble.=next;
      } else {
        $marble.=next for ^2;
        my Marble $new-marble .= new(prev => $marble.prev, next => $marble, number => $next-marble);
        $marble.prev.next = $new-marble;
        $marble.prev = $new-marble;
        $marble = $new-marble;
      }
    }

    @scores.max
  }
}

my regex coord { '-'? \d+ }
my regex pair { '<' \s* <x=coord> \s* ',' \s* <y=coord> \s* '>' }

class MovingPoint {
  has Int $.x is rw;
  has Int $.y is rw;
  has Int $.x_vel;
  has Int $.y_vel;
}

sub day10(Str $in) {
  my MovingPoint @points = $in.lines.map: {
    m/'position=' <pos=pair> ' velocity=' <vel=pair>/ or die;
    MovingPoint.new( x => +$<pos><x>, y => +$<pos><y>, x_vel => +$<vel><x>, y_vel => +$<vel><y>);
  };
  my $height = @points».y.minmax.elems;
  my $seconds = 0;

  loop {
    for @points { .x += .x_vel; .y += .y_vel };
    my $new-height = @points».y.minmax.elems;
    last if $new-height > $height;
    $height = $new-height;
    $seconds++;
  }

  for @points { .x -= .x_vel; .y -= .y_vel };
  my $width = @points».x.minmax.elems;
  my @grid = ['.' xx $width] xx $height;
  my $min_x = @points».x.min;
  my $min_y = @points».y.min;
  @grid[.y - $min_y; .x - $min_x] = '#' for @points;
  @grid.map(*.join).join("\n"), $seconds
}

multi advent('day10', '1', Str $in) { day10($in)[0] }
multi advent('day10', '2', Str $in) { day10($in)[1] }

multi advent('day11', '1', Str $in) {
  my int $grid-serial-number = $in.Int;
  my int @grid[300; 300];
  for 1..300 -> $x {
    for 1..300 -> $y {
      @grid[$x - 1; $y - 1] =
        ((($x + 10) * $y + $grid-serial-number) * ($x + 10)) div 100 % 10 - 5;
    }
  }
  my ($x, $y) = (^298 X ^298).map(-> ($x, $y) {
    ($x, $y) => (^3 X ^3).map(-> ($i, $j) { @grid[$x + $i; $y + $j] }).sum(:wrap)
  }).max(*.value).key;
  ($x + 1, $y + 1)
}

multi advent('day11', '2', Str $in) {
  my int $grid-serial-number = $in.Int;
  my int @square-sums[300; 300; 300]; # [x; y; size]
  for 1..300 -> $x {
    for 1..300 -> $y {
      @square-sums[$x - 1; $y - 1; 0] =
        ((($x + 10) * $y + $grid-serial-number) * ($x + 10)) div 100 % 10 - 5;
    }
  }
  my @max-key = (-1, -1, -1);
  my int $max = -1;
  for 2..300 -> $size {
    say $size;
    my $divisor = (2..($size div 2)).grep($size %% *).min;
    my int $gap = $size - 1;
    for ^(300 - $gap) -> $x {
      print '.';
      for ^(300 - $gap) -> $y {
        my int $sum = 0;
        if $divisor == Inf {
          $sum += @square-sums[$x; $y; $size - 2];
          $sum += @square-sums[$x + $_; $y + $gap; 0] for ^$gap;
          $sum += @square-sums[$x + $gap; $y + $_; 0] for ^$gap;
          $sum += @square-sums[$x + $gap; $y + $gap; 0];
        } else {
          my int $count = $divisor;
          my int $inner-size = $size div $divisor;
          for ^$count -> $i {
            for ^$count -> $j {
              $sum += @square-sums[$x + $i * $inner-size; $y + $j * $inner-size; $inner-size - 1];
            }
          }
        }
        @square-sums[$x; $y; $size - 1] = $sum;
        if $sum > $max {
          $max = $sum;
          @max-key = ($x + 1, $y + 1, $size);
        }
      }
    }
    say '';
  }
  @max-key
}

multi advent('day12', '1', Str $in) {
  my ($initial-str, $rules-str) = $in.split("\n\n");
  my $pots = $initial-str.split(': ')[1];
  my %rules is SetHash = $rules-str.split("\n").map({
    my ($k, $v) = .split(' => ');
    $k => $v[0] eq '#'
  });
  my $offset = 0;
  for ^20 {
    $offset -= 2;
    $pots = "....$pots....".comb.rotor(5 => -4).map({ %rules{.join} ?? '#' !! '.' }).join;
  }
  $pots.comb.pairs.grep(*.value eq '#').map(*.key + $offset).sum
}

multi advent('day12', '2', Str $in) {
  my ($initial-str, $rules-str) = $in.split("\n\n");
  my $pots = $initial-str.split(': ')[1];
  my %rules is SetHash = $rules-str.split("\n").map({
    my ($k, $v) = .split(' => ');
    $k => $v[0] eq '#'
  });
}

# ...## => #
# ..#.. => #
# .#... => #
# .#.#. => #
# .#.## => #
# .##.. => #
# .#### => #
# #.#.# => #
# #.### => #
# ##.#. => #
# ##.## => #
# ###.. => #
# ###.# => #
# ####. => #

multi advent('day13', '1', Str $in) {
  ...
}

multi advent('day13', '2', Str $in) {
  ...
}

multi advent('day14', '1', Str $in) {
  ...
}

multi advent('day14', '2', Str $in) {
  ...
}

multi advent('day15', '1', Str $in) {
  ...
}

multi advent('day15', '2', Str $in) {
  ...
}

multi advent('day16', '1', Str $in) {
  ...
}

multi advent('day16', '2', Str $in) {
  ...
}

multi advent('day17', '1', Str $in) {
  ...
}

multi advent('day17', '2', Str $in) {
  ...
}

multi advent('day18', '1', Str $in) {
  ...
}

multi advent('day18', '2', Str $in) {
  ...
}

multi advent('day19', '1', Str $in) {
  ...
}

multi advent('day19', '2', Str $in) {
  ...
}

multi advent('day20', '1', Str $in) {
  ...
}

multi advent('day20', '2', Str $in) {
  ...
}

multi advent('day21', '1', Str $in) {
  ...
}

multi advent('day21', '2', Str $in) {
  ...
}

multi advent('day22', '1', Str $in) {
  ...
}

multi advent('day22', '2', Str $in) {
  ...
}

multi advent('day23', '1', Str $in) {
  ...
}

multi advent('day23', '2', Str $in) {
  ...
}

multi advent('day24', '1', Str $in) {
  ...
}

multi advent('day24', '2', Str $in) {
  ...
}

multi advent('day25', '1', Str $in) {
  ...
}

multi advent('day25', '2', Str $in) {
  ...
}
