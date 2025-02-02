import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/main.dart';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/tools/io_tools.dart';
import 'package:pica_comic/views/settings/explore_settings.dart';
import 'package:pica_comic/views/settings/ht_settings.dart';
import 'package:pica_comic/views/settings/picacg_settings.dart';
import 'package:pica_comic/views/widgets/pop_up_widget_scaffold.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../foundation/app.dart';
import '../app_views/logs_page.dart';
import '../widgets/select.dart';
import 'eh_settings.dart';
import 'jm_settings.dart';
import 'app_settings.dart';
import 'package:pica_comic/tools/translations.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({this.popUp = false, Key? key}) : super(key: key);
  final bool popUp;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool checkUpdateValue = appdata.settings[2] == "1";
  bool blockScreenshot = appdata.settings[12] == "1";
  bool needBiometrics = appdata.settings[13] == "1";

  @override
  Widget build(BuildContext context) {
    var body = SingleChildScrollView(
      child: Column(
        children: [
          buildExploreSettings(context, widget.popUp),
          const Divider(),
          PicacgSettings(widget.popUp),
          const Divider(),
          EhSettings(widget.popUp),
          const Divider(),
          JmSettings(widget.popUp),
          const Divider(),
          HtSettings(widget.popUp),
          const Divider(),
          // Encountering some issues, temporarily disable this option.
          //buildNhentaiSettings(),
          //const Divider(),
          buildAppearanceSettings(),
          const Divider(),
          buildAppSettings(),
          const Divider(),
          buildPrivacySettings(),
          const Divider(),
          buildAboutSettings(),
          SizedBox(
            height: MediaQuery.of(context).padding.bottom,
          )
        ],
      ),
    );
    if (widget.popUp) {
      return PopUpWidgetScaffold(title: "设置".tl, body: body);
    } else {
      return Scaffold(
        appBar: AppBar(title: Text("设置".tl)),
        body: body,
      );
    }
  }

  Widget buildAppearanceSettings() => Card(
        elevation: 0,
        child: Column(
          children: [
            ListTile(
              title: Text("外观".tl),
            ),
            ListTile(
              leading: Icon(Icons.color_lens,
                  color: Theme.of(context).colorScheme.secondary),
              title: Text("主题选择".tl),
              trailing: Select(
                initialValue: int.parse(appdata.settings[27]),
                values: const [
                  "Dynamic",
                  "Blue",
                  "Light Blue",
                  "Indigo",
                  "Purple",
                  "Pink",
                  "Cyan",
                  "Teal",
                  "Yellow",
                  "Brown"
                ],
                whenChange: (i) {
                  appdata.settings[27] = i.toString();
                  appdata.updateSettings();
                  MyApp.updater?.call();
                },
                inPopUpWidget: widget.popUp,
                width: 140,
              ),
            ),
            ListTile(
              leading: Icon(Icons.dark_mode,
                  color: Theme.of(context).colorScheme.secondary),
              title: Text("深色模式".tl),
              trailing: Select(
                initialValue: int.parse(appdata.settings[32]),
                values: ["跟随系统".tl, "禁用".tl, "启用".tl],
                whenChange: (i) {
                  appdata.settings[32] = i.toString();
                  appdata.updateSettings();
                  MyApp.updater?.call();
                },
                inPopUpWidget: widget.popUp,
                width: 140,
              ),
            ),
            if (App.isAndroid)
              ListTile(
                leading: Icon(Icons.smart_screen_outlined,
                    color: Theme.of(context).colorScheme.secondary),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("高刷新率模式".tl),
                    const SizedBox(
                      width: 2,
                    ),
                    InkWell(
                      borderRadius: const BorderRadius.all(Radius.circular(18)),
                      onTap: () => showDialogMessage(
                          context,
                          "高刷新率模式".tl,
                          "启用后, APP将尝试设置高刷新率\n"
                          "如果OS没有限制APP的刷新率, 无需启用此项\n"
                          "OS可能不会响应更改"),
                      child: const Icon(
                        Icons.info_outline,
                        size: 18,
                      ),
                    )
                  ],
                ),
                trailing: Switch(
                  value: appdata.settings[38] == "1",
                  onChanged: (b) {
                    setState(() {
                      appdata.settings[38] = b ? "1" : "0";
                    });
                    appdata.updateSettings();
                    if (b) {
                      try {
                        FlutterDisplayMode.setHighRefreshRate();
                      } catch (e) {
                        // ignore
                      }
                    } else {
                      try {
                        FlutterDisplayMode.setLowRefreshRate();
                      } catch (e) {
                        // ignore
                      }
                    }
                  },
                ),
              )
          ],
        ),
      );

  Widget buildAppSettings() => Card(
        elevation: 0,
        child: Column(
          children: [
            const ListTile(
              title: Text("App"),
            ),
              ListTile(
                leading: Icon(Icons.update,
                    color: Theme.of(context).colorScheme.secondary),
                title: Text("检查更新".tl),
                subtitle: Text("${"当前:".tl} $appVersion"),
                onTap: () {
                  findUpdate(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.security_update,
                    color: Theme.of(context).colorScheme.secondary),
                title: Text("启动时检查更新".tl),
                trailing: Switch(
                  value: checkUpdateValue,
                  onChanged: (b) {
                    b ? appdata.settings[2] = "1" : appdata.settings[2] = "0";
                    setState(() => checkUpdateValue = b);
                    appdata.writeData();
                  },
                ),
                onTap: () {},
              ),
            if (App.isWindows || App.isAndroid)
              ListTile(
                leading: Icon(Icons.folder,
                    color: Theme.of(context).colorScheme.secondary),
                title: Text("设置下载目录".tl),
                trailing: const Icon(Icons.arrow_right),
                onTap: () => setDownloadFolder(),
              ),
              StateBuilder<CalculateCacheLogic>(
                  init: CalculateCacheLogic(),
                  builder: (logic) {
                    if (logic.calculating) {
                      logic.get();
                      return ListTile(
                        leading: Icon(Icons.storage,
                            color: Theme.of(context).colorScheme.secondary),
                        title: Text("缓存大小".tl),
                        subtitle: Text("计算中".tl),
                        onTap: () {},
                      );
                    } else {
                      return ListTile(
                        leading: Icon(Icons.storage,
                            color: Theme.of(context).colorScheme.secondary),
                        title: Text("清除缓存".tl),
                        subtitle: Text(
                            "${logic.size == double.infinity ? "未知" : logic.size.toStringAsFixed(2)} MB"),
                        onTap: () {
                          if (App.isAndroid ||
                              App.isIOS ||
                              App.isWindows) {
                            showConfirmDialog(context, "清除缓存".tl, "确认清除缓存?".tl,
                                () {
                              eraseCache();
                              logic.size = 0;
                              logic.update();
                            });
                          }
                        },
                      );
                    }
                  }),
            ListTile(
              leading: Icon(Icons.chrome_reader_mode,
                  color: Theme.of(context).colorScheme.secondary),
              title: Text("阅读器缓存限制".tl),
              trailing: const Icon(Icons.arrow_right),
              onTap: () => setCacheLimit(context),
            ),
            ListTile(
              leading: Icon(Icons.bug_report,
                  color: Theme.of(context).colorScheme.secondary),
              title: const Text("Logs"),
              trailing: const Icon(Icons.arrow_right),
              onTap: () => App.globalTo(() => const LogsPage()),
            ),
            ListTile(
              leading: Icon(Icons.delete,
                  color: Theme.of(context).colorScheme.secondary),
              title: Text("清除所有数据".tl),
              trailing: const Icon(Icons.arrow_right),
              onTap: () => clearUserData(context),
            ),
            ListTile(
              leading: Icon(Icons.sim_card_download,
                  color: Theme.of(context).colorScheme.secondary),
              title: Text("导出用户数据".tl),
              trailing: const Icon(Icons.arrow_right),
              onTap: () => exportDataSetting(context),
            ),
            ListTile(
              leading: Icon(Icons.data_object,
                  color: Theme.of(context).colorScheme.secondary),
              title: Text("导入用户数据".tl),
              trailing: const Icon(Icons.arrow_right),
              onTap: () => importDataSetting(context),
            ),
            ListTile(
              leading: Icon(Icons.sync,
                  color: Theme.of(context).colorScheme.secondary),
              title: Text("数据同步".tl),
              trailing: const Icon(Icons.arrow_right),
              onTap: () => syncDataSettings(context),
            )
          ],
        ),
      );

  Widget buildPrivacySettings() => Card(
        elevation: 0,
        child: Column(
          children: [
            ListTile(
              title: Text("隐私".tl),
            ),
            if (App.isAndroid)
              ListTile(
                leading: Icon(Icons.screenshot,
                    color: Theme.of(context).colorScheme.secondary),
                title: Text("阻止屏幕截图".tl),
                subtitle: Text("需要重启App以应用更改".tl),
                trailing: Switch(
                  value: blockScreenshot,
                  onChanged: (b) {
                    b ? appdata.settings[12] = "1" : appdata.settings[12] = "0";
                    setState(() => blockScreenshot = b);
                    appdata.writeData();
                  },
                ),
              ),
            ListTile(
                leading: Icon(Icons.security,
                    color: Theme.of(context).colorScheme.secondary),
                title: Text("需要身份验证".tl),
                subtitle: Text("如果系统中未设置任何认证方法请勿开启".tl),
                trailing: Switch(
                  value: needBiometrics,
                  onChanged: (b) {
                    b ? appdata.settings[13] = "1" : appdata.settings[13] = "0";
                    setState(() => needBiometrics = b);
                    appdata.writeData();
                  },
                )),
          ],
        ),
      );

  Widget buildAboutSettings() => Card(
        elevation: 0,
        child: Column(
          children: [
            ListTile(
              title: Text("关于".tl),
            ),
            ListTile(
              leading: Icon(Icons.info_outline,
                  color: Theme.of(context).colorScheme.secondary),
              title: const Text("PicaComic"),
              subtitle: Text("本软件仅用于学习交流".tl),
              onTap: () => showMessage(context, "禁止涩涩"),
            ),
            ListTile(
              leading: Icon(Icons.code,
                  color: Theme.of(context).colorScheme.secondary),
              title: Text("项目地址".tl),
              subtitle: const Text("https://github.com/wgh136/PicaComic"),
              onTap: () => launchUrlString(
                  "https://github.com/wgh136/PicaComic",
                  mode: LaunchMode.externalApplication),
            ),
            ListTile(
              leading: Icon(Icons.chat,
                  color: Theme.of(context).colorScheme.secondary),
              title: Text("提出建议".tl),
              onTap: () => giveComments(context),
            ),
          ],
        ),
      );

  Widget buildNhentaiSettings(){
    final values = ["nhentai.net", "nhentai.xxx"];
    return Card(
      elevation: 0,
      child: Column(
        children: [
          ListTile(
            title: Text("关于".tl),
          ),
          ListTile(
            leading: Icon(Icons.domain,
                color: Theme.of(context).colorScheme.secondary),
            title: const Text("Domain"),
            trailing: Select(
              values: values,
              initialValue: values.indexOf(appdata.settings[48].replaceFirst("https://", "")),
              inPopUpWidget: widget.popUp,
              whenChange: (i){
                appdata.settings[48] = "https://${values[i]}";
                appdata.updateSettings();
                NhentaiNetwork().init();
              },
              width: 160,
            ),
          )
        ],
      ),
    );
  }
}
