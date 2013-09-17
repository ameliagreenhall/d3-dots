(function() {
  var BusStopBasic, colorOfDayScale, initSVG, makeBusLine, makeSunChange, passengerEnters, passengerExits;

  colorOfDayScale = d3.scale.linear().domain([0, 23]);

  colorOfDayScale.domain([0.0, 0.20, 0.21875, 0.23958333333333334, 0.25, 0.2708333333333333, 0.2916666666666667, 0.3125, 0.3333333333333333, 0.375, 0.4166666666666667, 0.5, 0.5416666666666666, 0.5833333333333334, 0.625, 0.6666666666666666, 0.7083333333333334, 0.75, 0.7708333333333334, 0.7916666666666666, 0.8125, 0.8333333333333334, 0.8541666666666666, 0.875, 0.916].map(colorOfDayScale.invert));

  colorOfDayScale.range(["#01062d", "#2b1782", "#600eae", "#9b13bb", "#b13daf", "#d086b5", "#dfa7ac", "#ebc8ab", "#f3dfbc", "#fef6aa", "#fefdea", "#fbf4a5", "#f0d681", "#fbf8da", "#f5f1ba", "#f0e435", "#f4be51", "#ec2523", "#a82358", "#712b80", "#4a3f96", "#188dba", "#1c71a3", "#173460", "#020b2f"]);

  initSVG = function(selector, width, height) {
    var dimensions, g, margin, svg_route;
    if (width == null) {
      width = 800;
    }
    if (height == null) {
      height = 500;
    }
    margin = {
      top: 20,
      right: 20,
      bottom: 20,
      left: 20
    };
    width = width - margin.left - margin.right;
    height = height - margin.top - margin.bottom;
    dimensions = {
      margin: margin,
      width: width,
      height: height
    };
    svg_route = d3.select(selector).append('svg').attr({
      width: width + margin.left + margin.right,
      height: height + margin.top + margin.bottom
    });
    g = svg_route.append("g").attr({
      transform: translate(margin.left, margin.top)
    });
    return {
      g: g,
      dimensions: dimensions
    };
  };

  makeSunChange = function(kind) {
    var dur, hours, makeBus, svg, width;
    if (kind == null) {
      kind = 'sunrise';
    }
    console.log("make " + kind);
    dur = 750;
    hours = kind === 'sunrise' ? d3.range(12) : d3.range(12, 22);
    hours.forEach(function(hour, i) {
      return d3.select("section." + kind).transition().delay(dur * i).duration(dur).ease('linear').style('background-color', d3.rgb(colorOfDayScale(hour)));
    });
    $('.bus-route', '.deck-next').empty();
    svg = initSVG('.deck-next .bus-route', window.innerWidth, 200);
    width = svg.dimensions.width;
    makeBus = function() {
      var bus, finalPos, initDur, initPos, trans;
      bus = svg.g.selectAll('.bus').data([
        {
          xpos: 0
        }
      ]).enter().append('image').attr({
        'xlink:href': kind === 'sunrise' ? "img/bus-inbound.png" : "img/bus-outbound-night.png",
        "class": "bus",
        width: '50px',
        height: '50px',
        x: kind === 'sunrise' ? -100 : width + 100,
        y: 50
      });
      if (kind === 'sunrise') {
        initPos = 50;
        finalPos = width + 50;
      } else {
        initPos = width - 50;
        finalPos = -100;
      }
      bus.transition().delay(500).duration(500).attr('x', initPos);
      initDur = 1000;
      trans = bus.transition().delay(initDur + 1000).duration(3000).attr('x', finalPos);
      if (kind === 'sunrise') {
        trans.each('end', function() {
          return $.deck('next');
        });
      } else {
        trans.each('end', function() {
          return d3.select('#final-contact').transition().style('opacity', 1);
        });
      }
    };
    return setTimeout(makeBus, dur * 12 + 500);
  };

  makeBusLine = function(showLoading) {
    var line_maker, margin, stops, svg, yVal;
    if (showLoading == null) {
      showLoading = false;
    }
    $('.deck-next .bus-route').empty();
    svg = initSVG('.deck-next .bus-route', 800);
    margin = svg.dimensions.margin;
    yVal = svg.dimensions.height / 2;
    line_maker = d3.svg.line().x(function(d) {
      return d;
    }).y(yVal);
    stops = d3.json('data/stops.json', function(data) {
      var Tmax, initDelay, line, loopBus, rScale, xScale;
      xScale = d3.scale.linear().domain(d3.extent(data, function(d) {
        return d.distance;
      })).range([margin.left, svg.dimensions.width - margin.right]);
      rScale = d3.scale.linear().domain(d3.extent(data, function(d) {
        return d.count;
      })).range([7, 25]);
      line = svg.g.append("path").datum(xScale.range()).attr({
        d: line_maker,
        "class": "bus-route"
      });
      stops = svg.g.selectAll("circle.bus-stop").data(data).enter().append("circle").attr({
        "class": "bus-stop",
        r: 5,
        cx: function(d) {
          return xScale(d.distance);
        },
        cy: yVal
      });
      Tmax = data[data.length - 1].time;
      initDelay = 1000;
      loopBus = function() {
        var bus, dropBus;
        bus = svg.g.selectAll('circle.bus').data([1]).enter().append('circle').attr({
          "class": 'bus',
          cx: xScale(0),
          cy: yVal,
          r: rScale(0)
        });
        d3.range(1, data.length).forEach(function(i) {
          var delay, dt, t;
          delay = initDelay + data[i - 1].time;
          dt = data[i].time - data[i - 1].time;
          t = bus.transition().duration(dt).delay(delay).attr('cx', xScale(data[i].distance));
          if (showLoading) {
            return t.attr('r', rScale(data[i].count));
          }
        });
        dropBus = function() {
          return bus.data([]).exit().remove();
        };
        return setTimeout(dropBus, initDelay + Tmax + 500);
      };
      return setInterval(loopBus, initDelay + Tmax + 600);
    });
  };

  BusStopBasic = (function() {
    function BusStopBasic() {
      var line_maker, margin, svg, tick_fn, xScale, yScale,
        _this = this;
      $('.deck-next .bus-stop').empty();
      svg = initSVG('.deck-next .bus-stop', 800);
      margin = svg.dimensions.margin;
      xScale = d3.scale.linear().range([margin.left, svg.dimensions.width - margin.right]);
      yScale = d3.scale.linear().range([svg.dimensions.height - margin.top, 0 + margin.bottom]);
      line_maker = d3.svg.line().x(function(d) {
        return d;
      }).y(yScale(0.5));
      this.line = svg.g.append("path").datum(xScale.range()).attr({
        d: line_maker,
        "class": "bus-route"
      });
      this.stops = svg.g.selectAll("circle.bus-stop").data([0, 0.5, 1]).enter().append("circle").attr({
        "class": "bus-stop",
        r: 5,
        cx: function(d) {
          return xScale(d);
        },
        cy: yScale(0.5)
      });
      this.bus = svg.g.append('circle').attr({
        "class": 'bus',
        cx: xScale(0.5),
        cy: yScale(0.5),
        r: 8
      });
      this.stop = {
        count_enter: 8,
        count_exit: 10,
        distance: 0.5
      };
      this.svg = svg;
      this.xScale = xScale;
      this.yScale = yScale;
      this.passengers = [];
      this.passengerCircles = this.svg.g.selectAll("circle.passenger");
      tick_fn = function(e) {
        var k;
        k = .9 * e.alpha;
        _this.passengers.forEach(function(o, i) {
          o.x += (_this.xScale(_this.stop.distance) - o.x) * k;
          return o.y += (_this.yScale(0.6) - o.y) * k;
        });
        _this.passengerCircles.attr({
          cx: function(d) {
            return d.x;
          },
          cy: function(d) {
            return d.y;
          }
        });
      };
      this.force = d3.layout.force().links([]).gravity(0).friction(0.2).charge(-80).size([this.svg.dimensions.width, this.svg.dimensions.height]).nodes(this.passengers).on('tick', tick_fn);
    }

    BusStopBasic.prototype.randX = function() {
      return this.xScale(this.stop.distance) + (Math.random() - 0.5) * this.xScale(1) / 4;
    };

    BusStopBasic.prototype.randY = function() {
      return this.yScale(getRandomRange(0.5, 1));
    };

    BusStopBasic.prototype.addPassenger = function(psgr) {
      this.passengers.push(psgr);
      return this.redrawPassengers();
    };

    BusStopBasic.prototype.redrawPassengers = function(dur) {
      var dropCircles,
        _this = this;
      if (dur == null) {
        dur = 1000;
      }
      this.force.nodes(this.passengers);
      this.passengerCircles = this.passengerCircles.data(this.force.nodes(), function(d) {
        return d.index;
      });
      this.passengerCircles.enter().append('circle').attr({
        "class": "passenger",
        cx: function(d) {
          return d.x;
        },
        cx: function(d) {
          return d.y;
        },
        r: function(d) {
          return 3;
        }
      }).style({
        fill: '#eee',
        stroke: d3.rgb('steelblue').darker(2),
        "stroke-width": 1.5
      }).call(this.force.drag);
      this.passengerCircles.exit().transition(dur).attr({
        cx: function(d) {
          return _this.xScale(_this.stop.distance);
        },
        cy: function(d) {
          return _this.yScale(0.5);
        }
      });
      dropCircles = function() {
        return _this.passengerCircles.exit().remove();
      };
      setTimeout(dropCircles, dur);
      this.force.start();
    };

    return BusStopBasic;

  })();

  passengerExits = function() {
    var bs, delay, duration, showExits, stop;
    console.log('make passenger exits');
    bs = new BusStopBasic();
    stop = bs.stop;
    duration = 2000;
    delay = 500;
    showExits = function() {
      var departing_data, departing_passengers, dropPassengers;
      departing_data = d3.range(stop.count_exit).map(function(i) {
        return {
          xEnd: bs.randX(),
          yEnd: bs.randY()
        };
      });
      departing_passengers = bs.svg.g.selectAll("circle.passenger-departing").data(departing_data).enter().append('circle');
      departing_passengers.attr({
        "class": "passenger-departing",
        cx: bs.xScale(stop.distance),
        cy: bs.yScale(0.5),
        r: 3
      }).style({
        fill: '#eee',
        stroke: d3.rgb('steelblue').darker(2),
        "stroke-width": 1.5
      });
      departing_passengers.transition().duration(duration).delay(delay).attr({
        cx: function(d) {
          return d.xEnd;
        },
        cy: function(d) {
          return d.yEnd;
        }
      }).style({
        'fill-opacity': 0.01
      });
      dropPassengers = function() {
        return departing_passengers.data([]).exit().remove();
      };
      return setTimeout(dropPassengers, delay + duration);
    };
    return setInterval(showExits, 3000);
  };

  passengerEnters = function() {
    var bs, showEnters;
    bs = new BusStopBasic();
    showEnters = function() {
      var passengersBoardFn;
      d3.range(bs.stop.count_enter).forEach(function(i) {
        var addFn, psgr;
        psgr = {
          time_appear: getRandomRange(0, 3000),
          x: bs.randX(),
          y: bs.randY()
        };
        addFn = function() {
          return bs.addPassenger(psgr);
        };
        return setTimeout(addFn, psgr.time_appear);
      });
      passengersBoardFn = function() {
        bs.passengers = [];
        return bs.redrawPassengers(1000);
      };
      return setTimeout(passengersBoardFn, 3200);
    };
    return setInterval(showEnters, 5000);
  };

  $(function() {
    var Nslides;
    $.deck('section');
    Nslides = $.deck('getSlides').length;
    $('#next').on('click', function() {
      return $.deck('next');
    });
    $('#next').hide();
    d3.select('section.sunrise').style('background-color', 'black');
    d3.select('#final-contact').style('opacity', 0);
    return $(document).bind('deck.change', function(event, fromSlide, toSlide) {
      var toHasClass;
      toHasClass = function(classNm) {
        return $.deck('getSlide', toSlide).hasClass(classNm);
      };
      if (toHasClass('sunrise')) {
        return makeSunChange('sunrise');
      } else if (toHasClass('linear')) {
        return makeBusLine();
      } else if (toHasClass('linear-load')) {
        return makeBusLine(true);
      } else if (toHasClass('passenger-exits')) {
        return passengerExits();
      } else if (toHasClass('passenger-arrivals')) {
        return passengerEnters();
      } else if (toHasClass('finished-product')) {
        $('#iframe').html("<iframe src='http://urban-data.herokuapp.com'></iframe>");
        return $('#next').show();
      } else if (toHasClass('sunset')) {
        $('#iframe').html('');
        $('#next').hide();
        return makeSunChange('sunset');
      }
    });
  });

}).call(this);
