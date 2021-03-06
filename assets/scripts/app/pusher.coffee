Travis.Pusher = (key) ->
  @init(key) if key
  this

$.extend Travis.Pusher,
  CHANNELS: ['common']
  CHANNEL_PREFIX: ''

$.extend Travis.Pusher.prototype,
  active_channels: []

  init: (key) ->
    Pusher.warn = @warn.bind(this)
    @pusher = new Pusher(key)
    @subscribe(channel) for channel in Travis.Pusher.CHANNELS

  subscribe: (channel) ->
    if @pusher && @active_channels.indexOf(channel) == -1
      @active_channels.push(channel)
      @pusher.subscribe(@prefix(channel)).bind_all((event, data) => @receive(event, data))

  unsubscribe: (channel) ->
    ix = @active_channels.indexOf(channel)
    if @pusher && ix == -1
      @active_channels.splice(ix, 1)
      @pusher.unsubscribe(@prefix(channel))

  prefix: (channel) ->
    "#{Travis.Pusher.CHANNEL_PREFIX}#{channel}"

  receive: (event, data) ->
    return if event.substr(0, 6) == 'pusher'
    data = @normalize(event, data) if data.id
    Ember.run.next ->
      Travis.app.store.receive(event, data)

  normalize: (event, data) ->
    switch event
      when 'build:started', 'build:finished'
        data
      when 'job:created', 'job:started', 'job:finished', 'job:log'
        data.queue = data.queue.replace('builds.', '') if data.queue
        { job: data }
      when 'worker:added', 'worker:updated', 'worker:removed'
        { worker: data }

  warn: (type, warning) ->
    console.warn(warning) unless @ignoreWarning(warning)

  ignoreWarning: (warning) ->
    if message = warning.data?.message
      message.indexOf('Existing subscription') == 0 or message.indexOf('No current subscription') == 0
