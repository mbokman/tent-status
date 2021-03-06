class Reposted extends TentStatus.Events
  separator: "__SEP__"

  constructor: ->
    return unless TentStatus.config.current_entity
    @params = {
      post_types: "https://tent.io/types/post/repost/v0.1.0"
      entity: TentStatus.config.current_entity.toStringWithoutSchemePort()
      limit: 50
    }

    TentStatus.Cache.get @_sinceIdCacheKey(), (since_id) =>
      if since_id
        @params.since_id = since_id

      new HTTP 'GET', "#{TentStatus.config.tent_api_root}/posts", @params, (reposts, xhr) =>
        return unless xhr.status == 200
        return unless reposts and reposts.length
        TentStatus.Cache.set @_sinceIdCacheKey(), _.first(reposts).id, {saveToLocalStorage:true}
        for repost in reposts
          post_id = repost.content.id
          post_entity = repost.content.entity
          @setReposted post_id, post_entity, @params.entity

  on: (event, entity, post_id, fn) =>
    return unless TentStatus.config.current_entity
    if event == 'change' and entity and post_id
      @isReposted post_id, entity, (is_reposted) =>
        fn?(is_reposted) if is_reposted
    super("#{event}#{@separator}#{entity}#{@separator}#{post_id}", fn)

  setReposted: (post_id, post_entity, current_entity = @params.entity) =>
    return unless TentStatus.config.current_entity
    TentStatus.Cache.set @_cacheKey(post_id, post_entity, current_entity), true, {saveToLocalStorage:true}
    @trigger "change#{@separator}#{post_entity}#{@separator}#{post_id}", true

  unsetReposted: (post_id, post_entity, current_entity = @params.entity) =>
    return unless TentStatus.config.current_entity
    TentStatus.Cache.remove @_cacheKey(post_id, post_entity, current_entity)
    @trigger "change#{@separator}#{post_entity}#{@separator}#{post_id}", false

  isReposted: (post_id, post_entity, callback, current_entity = @params.entity) =>
    return callback() unless TentStatus.config.current_entity
    TentStatus.Cache.get @_cacheKey(post_id, post_entity, current_entity), (is_reposted) =>
      callback !!is_reposted

  _cacheKey: (post_id, post_entity, current_entity) =>
    "reposted:#{current_entity}#{@separator}#{post_entity}#{@separator}#{post_id}"

  _sinceIdCacheKey: => "reposted:#{@params.entity}:since_id"

TentStatus.Reposted = new Reposted
