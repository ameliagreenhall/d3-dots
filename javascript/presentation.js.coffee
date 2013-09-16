colorOfDayScale = d3.scale.linear()
  .domain([0,23])
colorOfDayScale.domain([0.0, 0.20, 0.21875, 0.23958333333333334, 0.25, 0.2708333333333333, 0.2916666666666667, 0.3125,  0.3333333333333333, 0.375, 0.4166666666666667, 0.5, 0.5416666666666666, 0.5833333333333334, 0.625, 0.6666666666666666, 0.7083333333333334, 0.75,
 0.7708333333333334, 0.7916666666666666, 0.8125, 0.8333333333333334, 0.8541666666666666, 0.875, 0.916].map(colorOfDayScale.invert))
colorOfDayScale.range(["#01062d","#2b1782","#600eae","#9b13bb","#b13daf","#d086b5","#dfa7ac","#ebc8ab","#f3dfbc","#fef6aa","#fefdea","#fbf4a5","#f0d681","#fbf8da","#f5f1ba","#f0e435","#f4be51","#ec2523","#a82358","#712b80","#4a3f96","#188dba","#1c71a3","#173460","#020b2f"])

initSVG = (selector, width=800) -> 
  margin =
    top: 20
    right: 20
    bottom: 20
    left: 20
  width = width - margin.left - margin.right
  height = 500 - margin.top - margin.bottom

  dimensions = 
    margin: margin
    width: width
    height: height

  svg_route = d3.select(selector).append('svg').attr
    width: width + margin.left + margin.right
    height: height + margin.top + margin.bottom
  g = svg_route.append("g").attr
    transform: translate(margin.left, margin.top)  
  return {g: g, dimensions: dimensions}
  
makeSunChange = (kind='sunrise') ->
  console.log("make #{kind}")
  dur = 750
  hours = if kind == 'sunrise' then d3.range(12) else d3.range(12, 22)
  hours.forEach (hour, i) ->
    d3.select("section.#{kind}").transition()
      .delay(dur * i)
      .duration(dur)
      .ease('linear')
      .style('background-color', d3.rgb(colorOfDayScale(hour)))
  $('.bus-route', '.deck-next').empty()

  svg = initSVG('.deck-next .bus-route', window.innerWidth)
  width = svg.dimensions.width

  makeBus = () ->
    bus = svg.g.selectAll('.bus').data([{xpos: 0}]).enter()
      .append('image')
      .attr
        'xlink:href': if kind == 'sunrise' then "img/bus-inbound.png" else "img/bus-outbound-night.png"
        class: "bus"
        width: '50px'
        height: '50px'
        x: if kind == 'sunrise' then -100 else (width + 100)
        y: 50

    if kind == 'sunrise'  
      initPos = 50
      finalPos = width + 50
    else
      initPos = width - 50
      finalPos = -100
    bus.transition().delay(500).duration(500)
      .attr('x', initPos)

    initDur = 1000
    trans = bus.transition().delay(initDur + 1000).duration(3000)
      .attr('x', finalPos)
    if kind == 'sunrise'
      trans.each('end', () -> $.deck('next'))
    return
  
  setTimeout(makeBus, dur * 12 + 500)


makeBusLine = (showLoading=false) ->
  $('.deck-next .bus-route').empty()
  svg = initSVG('.deck-next .bus-route', 800)
  margin = svg.dimensions.margin
  yVal = svg.dimensions.height / 2
  line_maker = d3.svg.line()
    .x((d) -> d)
    .y(yVal)
    
  stops = d3.json 'data/stops.json', (data) ->
    xScale = d3.scale.linear()
      .domain(d3.extent(data, (d) -> d.distance))
      .range([margin.left, svg.dimensions.width - margin.right]) 
    rScale = d3.scale.linear()
       .domain(d3.extent(data, (d) -> d.count))
       .range([7, 15])
       
    line = svg.g.append("path")
      .datum(xScale.range())
      .attr
        d: line_maker
        class: "bus-route"
    stops = svg.g.selectAll("circle.bus-stop")
      .data(data).enter()
      .append("circle").attr
        class: "bus-stop"
        r: 5
        cx: (d) -> xScale(d.distance)
        cy: yVal
  
    bus = svg.g.append('circle').attr
      class: 'bus'
      cx: xScale(0)
      cy: yVal
      r: rScale(0)
    
    initDelay = 1000
    
    d3.range(1, data.length).forEach (i) ->
      delay = initDelay + data[i-1].time
      dt = data[i].time - data[i-1].time
      t = bus.transition().duration(dt).delay(delay)
        .attr('cx', xScale(data[i].distance))
      if showLoading
        t.attr('r', rScale(data[i].count))
  
  return

class BusStopBasic
  constructor: () ->
    # make a line with a stop at the center 
    $('.deck-next .bus-stop').empty()
    svg = initSVG('.deck-next .bus-stop', 800)
    margin = svg.dimensions.margin
    xScale = d3.scale.linear()
      .range([margin.left, svg.dimensions.width - margin.right])   
    yScale = d3.scale.linear()
      .range([svg.dimensions.height - margin.top, 0 + margin.bottom])
    line_maker = d3.svg.line().x((d) -> d).y(yScale(0.5))
    
    @line = svg.g.append("path")
      .datum(xScale.range())
      .attr
        d: line_maker
        class: "bus-route"
    @stops = svg.g.selectAll("circle.bus-stop")
      .data([0, 0.5, 1]).enter()
      .append("circle").attr
        class: "bus-stop"
        r: 5
        cx: (d) -> xScale(d)
        cy: yScale(0.5)
    
    @bus = svg.g.append('circle').attr
      class: 'bus'
      cx: xScale(0.5)
      cy: yScale(0.5)
      r: 8
    @stop =
      count_enter: 8
      count_exit: 10
      distance: 0.5    
    @svg = svg
    @xScale = xScale
    @yScale = yScale

    @passengers = []
    @passengerCircles = @svg.g.selectAll("circle.passenger") # TODO- unique id

    tick_fn = (e) =>
      # Push nodes toward their designated focus.
      k = .9 * e.alpha
      @passengers.forEach (o, i) =>
        o.x += (@xScale(@stop.distance) - o.x) * k
        o.y += (@yScale(0.6) - o.y) * k
      @passengerCircles.attr
        cx: (d) -> d.x
        cy: (d) -> d.y
      return

    @force = d3.layout.force()
      .links([])
      .gravity(0)
      .friction(0.2)
      .charge(-80)
      .size([@svg.dimensions.width, @svg.dimensions.height])
      .nodes(@passengers)
      .on('tick', tick_fn)


  randX: () ->
    @xScale(@stop.distance) + (Math.random() - 0.5) * @xScale(1) / 4
  randY: () ->
    @yScale(getRandomRange(0.5, 1))

  addPassenger: (psgr) ->
    @passengers.push(psgr)
    @redrawPassengers()
    
  redrawPassengers: (dur=1000) ->
    @force.nodes(@passengers)
    @passengerCircles = @passengerCircles.data(@force.nodes(), (d) -> d.index)
    # enter
    @passengerCircles.enter().append('circle').attr
      class: "passenger"
      cx: (d) -> d.x
      cx: (d) -> d.y
      r: (d) -> 3
    .style
      fill: '#eee'
      stroke: d3.rgb('steelblue').darker(2)
      "stroke-width": 1.5
    .call(@force.drag)

    # exit (on boarding)
    @passengerCircles.exit()
      .transition(dur)
      .attr
        cx: (d) => @xScale(@stop.distance)
        cy: (d) => @yScale(0.5)
    dropCircles = () => @passengerCircles.exit().remove()
    setTimeout(dropCircles, dur)
    @force.start() 
    return
    
passengerExits = () -> 
  console.log 'make passenger exits'
  bs = new BusStopBasic()
  stop = bs.stop  
  
  # set the duration of the departure
  duration = 2000
  delay = 500

  showExits = () -> 
    departing_data = d3.range(stop.count_exit).map (i) ->
      xEnd: bs.randX()
      yEnd: bs.randY()
  
    departing_passengers = bs.svg.g.selectAll("circle.passenger-departing")
      .data(departing_data)
      .enter().append('circle')

    departing_passengers.attr
        class: "passenger-departing"
        cx: bs.xScale(stop.distance)
        cy: bs.yScale(0.5)
        r: 3
      .style
        fill: '#eee'
        stroke: d3.rgb('steelblue').darker(2)
        "stroke-width": 1.5
    # fade out and move to some random position near the stop
    departing_passengers.transition()
      .duration(duration)
      .delay(delay)
      .attr
        cx: (d) -> d.xEnd
        cy: (d) -> d.yEnd
      .style
        'fill-opacity': 0.01

    # when transition ends - remove the data
    dropPassengers = () -> 
      departing_passengers.data([]).exit().remove()
    setTimeout(dropPassengers, delay + duration)

  setInterval(showExits, 3000)
  
passengerEnters = () ->
  bs = new BusStopBasic()
  d3.range(bs.stop.count_enter).forEach (i) ->
    psgr =
      time_appear: getRandomRange(0, 3000)
      x: bs.randX()
      y: bs.randY()
    addFn = () -> bs.addPassenger(psgr)
    setTimeout(addFn, psgr.time_appear)
  
  passengersBoardFn = () -> 
    bs.passengers = []
    bs.redrawPassengers(2000)
  setTimeout(passengersBoardFn, 3200)


$ ->
  $.deck('section')
  Nslides = $.deck('getSlides').length

  $('#next').on 'click', () -> $.deck('next')
  $('#next').hide()  

  d3.select('section.sunrise').style('background-color', 'black')

  $(document).bind 'deck.change', (event, fromSlide, toSlide) -> 
    console.log(fromSlide, toSlide)
    if $.deck('getSlide', toSlide).hasClass('sunrise')
      makeSunChange('sunrise')
    else if fromSlide == 6 & toSlide == 7
      makeBusLine() # Run a bus along a line
    else if fromSlide == 7 & toSlide == 8
      makeBusLine(true) # Scale the bus by passenger load
    else if fromSlide == 8 & toSlide == 9
      passengerExits() # Show passengers exiting a bus
    else if fromSlide == 9 & toSlide == 10
      passengerEnters()
    else if $.deck('getSlide', toSlide).hasClass('finished-product')
      $('#iframe').html("<iframe src='http://urban-data.herokuapp.com'></iframe>")
      $('#next').show()
    else if $.deck('getSlide', toSlide).hasClass('conclusion')
      $('#iframe').html('') # turn off dots on the bus
      $('#next').hide()
    else if $.deck('getSlide', toSlide).hasClass('sunset')
      makeSunChange('sunset')