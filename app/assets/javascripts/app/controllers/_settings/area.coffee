class App.SettingsArea extends App.Controller
  constructor: ->
    super

    # check authentication
    @authenticateCheckRedirect()

    App.Setting.fetchFull(
      @render
      force: false
    )

  render: =>

    # serach area settings
    settings = App.Setting.search(
      filter:
        area: @area
    )

    # filter online service settings
    if App.Config.get('system_online_service')
      settings = _.filter(settings, (setting) ->
        return if setting.online_service
        return if setting.preferences && setting.preferences.online_service_disable
        setting
      )
      return if _.isEmpty(settings)

    # sort by prio
    settings = _.sortBy( settings, (setting) ->
      return if !setting.preferences
      setting.preferences.prio
    )

    elements = []
    for setting in settings
      if setting.preferences.controller && App[setting.preferences.controller]
        item = new App[setting.preferences.controller](setting: setting)
      else
        item = new App.SettingsAreaItem(setting: setting)
      elements.push item.el

    @html elements
