_.extend TentStatus.Helpers,
  formatTime: (time_or_int) ->
    now = moment()
    time = moment.unix(time_or_int)

    formatted_time = if time.format('YYYY-MM-DD') == now.format('YYYY-MM-DD')
      time.format('HH:mm') # time only
    else
      time.format('DD/MM/YY') # date and time

    "#{formatted_time}"

  rawTime: (time_or_int) ->
    moment.unix(time_or_int).format()

  minimalEntity: (entity) ->
    if TentStatus.config.tent_host_domain && entity.match(new RegExp("([a-z0-9]{2,})\.#{TentStatus.config.tent_host_domain}"))
      RegExp.$1
    else
      entity

  formatUrl: (url='') ->
    url.replace(/^\w+:\/\/([^\/]+).*?$/, '$1')

  formatUrlWithPath: (url = '') ->
    url.replace(/^\w+:\/\/(.*)$/, '$1')

  replaceIndexRange: (start_index, end_index, string, replacement) ->
    string.substr(0, start_index) + replacement + string.substr(end_index, string.length-1)

  # HTML escaping
  HTML_ENTITIES: {
    '&': '&amp;',
    '>': '&gt;',
    '<': '&lt;',
    '"': '&quot;',
    "'": '&#39;'
  }
  htmlEscapeText: (text) ->
    return unless text
    text.replace /[&"'><]/g, (character) -> TentStatus.Helpers.HTML_ENTITIES[character]

  flattenUrlsWithIndices: (items) ->
    _flattened = []
    for item in items
      for start_index, i in item.indices
        continue if i % 2
        end_index = item.indices[i+1]

        _item = _.clone(item)
        delete _item.indices
        _item.start_index = start_index
        _item.end_index = end_index
        _flattened.push _item
    _flattened

  truncate: (text, length, elipses='...') ->
    _truncated = text.substr(0, length-elipses.length)
    _truncated += elipses if text.length > length
    _truncated

  autoLinkText: (text) ->
    return unless text

    text = TentStatus.Helpers.htmlEscapeText(text)

    urls = TentStatus.Helpers.flattenUrlsWithIndices(TentStatus.Helpers.extractUrlsWithIndices text)
    mentions = TentStatus.Helpers.flattenUrlsWithIndices(
      TentStatus.Helpers.extractMentionsWithIndices(text, {exclude_urls: true, uniq: false})
    )

    return text unless urls.length or mentions.length

    updateIndicesWithOffset = (items, start_index, delta) ->
      items = for i in items
        if i.start_index >= start_index
          i.start_index += delta
          i.end_index += delta
        i
      items

    removeOverlappingItems = (items, start_index, end_index) ->
      _new_items = []
      for i in items
        _indices = [start_index..end_index]
        _i_indices = [i.start_index..i.end_index]
        unless _.intersection(_indices, _i_indices).length
          _new_items.push i
      _new_items

    urls_and_mentions = urls.concat(mentions)
    while urls_and_mentions.length
      item = urls_and_mentions.shift()
      original = text.substring(item.start_index, item.end_index)
      html = "<a href='#{TentStatus.Helpers.ensureUrlHasScheme(item.url)}'>" +
             TentStatus.Helpers.truncate(TentStatus.Helpers.formatUrlWithPath(original), TentStatus.config.URL_TRIM_LENGTH) + "</a>"
      delta = html.length - original.length
      updateIndicesWithOffset(urls_and_mentions, item.start_index, delta)
      urls_and_mentions = removeOverlappingItems(urls_and_mentions, item.start_index, item.end_index + delta)

      text = TentStatus.Helpers.replaceIndexRange(item.start_index, item.end_index, text, html)

    text

  simpleFormatText: (text = '') ->
    text.replace(/\n+(?!\s*\n)/g, "<br/>")

