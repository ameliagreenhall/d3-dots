colorOfDayScale = d3.scale.linear()
  .domain([0,23])
colorOfDayScale.domain([0.0, 0.20, 0.21875, 0.23958333333333334, 0.25, 0.2708333333333333, 0.2916666666666667, 0.3125,  0.3333333333333333, 0.375, 0.4166666666666667, 0.5, 0.5416666666666666, 0.5833333333333334, 0.625, 0.6666666666666666, 0.7083333333333334, 0.75,
 0.7708333333333334, 0.7916666666666666, 0.8125, 0.8333333333333334, 0.8541666666666666, 0.875, 0.916].map(colorOfDayScale.invert))
colorOfDayScale.range(["#01062d","#2b1782","#600eae","#9b13bb","#b13daf","#d086b5","#dfa7ac","#ebc8ab","#f3dfbc","#fef6aa","#fefdea","#fbf4a5","#f0d681","#fbf8da","#f5f1ba","#f0e435","#f4be51","#ec2523","#a82358","#712b80","#4a3f96","#188dba","#1c71a3","#173460","#020b2f"])

initSVG = (selector, width=window.innerWidth) -> 
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
  return {group: g, dimensions: dimensions}
  
makeSunChange = (kind='sunrise') ->
  console.log("make #{kind}")
  dur = 50# 750
  hours = if kind == 'sunrise' then d3.range(12) else d3.range(12, 24)
  hours.forEach (hour, i) ->
    d3.select('section.sunrise').transition()
      .delay(dur * i)
      .duration(dur)
      .ease('linear')
      .style('background-color', d3.rgb(colorOfDayScale(hour)))
  $('.bus-route', '.deck-next').empty()

  svg = initSVG('.deck-next .bus-route')
  width = svg.dimensions.width

  makeBus = () ->
    bus = svg.group.selectAll('.bus').data([{xpos: 0}]).enter()
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
      initPos = width + 50
      finalPos = 50
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
  svg = initSVG('.deck-next .bus-route', 800)
  margin = svg.dimensions.margin
  yVal = svg.dimensions.height / 2
  line_maker = d3.svg.line()
    .x((d) -> d)
    .y(yVal)
    
  stop_locs = [0, 3, 6, 6.5, 8, 10]
  xScale = d3.scale.linear()
    .domain(d3.extent(stop_locs))
    .range([margin.left, svg.dimensions.width - margin.right])    
  line = svg.group.append("path")
    .datum(xScale.range())
    .attr
      d: line_maker
      class: "bus-route"
  stops = svg.group.selectAll("circle.bus-stop")
    .data(stop_locs).enter()
    .append("circle").attr
      class: (d) -> "bus-stop"
      r: 5
      cx: (d) -> xScale(d)
      cy: yVal
  
  bus = svg.group.append('circle').attr
    class: 'bus'
    cx: xScale(0)
    cy: yVal
    r: 10
  
  dur = [800, 1000, 400, 600, 1200]
  dur.forEach (dt, i) ->
    delay = if i>0 then d3.sum(dur.slice(0,i)) else 0
    t = bus.transition().duration(dt).delay(delay)
      .attr('cx', xScale(stop_locs[i+1]))
    if showLoading
      t.attr('r', loading[i])
  
  
  return

$ ->
  $.deck('section')
  Nslides = $.deck('getSlides').length

  d3.select('section.sunrise').style('background-color', 'black')

  $(document).bind 'deck.change', (event, fromSlide, toSlide) -> 
    console.log(fromSlide, toSlide)
    if fromSlide == 0 & toSlide == 1
      makeSunChange('sunrise')
    else if fromSlide == 6 & toSlide == 7
      makeBusLine()
    else if fromSlide == (Nslides - 2) & toSlide == (Nslides - 1)
      makeSunChange('sunset')