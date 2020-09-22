import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'dart:io';
import 'dart:convert';
import 'package:finance_service/app_config.dart';
import 'package:finance_service/custom_icons_icons.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

void main({String env}) async {
  WidgetsFlutterBinding.ensureInitialized();
  final configuredApp = await AppConfig.forEnvironment(env);
  runApp(configuredApp);
}

class MyApp extends StatelessWidget {
  static String appName = 'Vahana Finance';
  Future<File> getCacheFile() async {
    var filePath = await DefaultCacheManager().getFilePath();
    String fileName = "cache.json";
    File file = new File(filePath + "/" + fileName);
    return file;
  }

  Future<String> getCacheData() async {
    String jsonData;
    var file = await getCacheFile();
    if (await file.exists()) {
      jsonData = file.readAsStringSync();
    } else {
      jsonData = '{}';
    }
    return jsonData;
  }

  Future<void> removeCacheFile() async {
    var file = await getCacheFile();
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> sendWhatsApp(String twilioBaseUrl, String twilioAccountSid, String twilioApikeySid, String twilioSecret, String twilioWhatsappNumber, String recipientNumber, String message) async {
    String url = '$twilioBaseUrl/$twilioAccountSid/Messages.json';
    String cred = '$twilioApikeySid:$twilioSecret';
    var bytes = utf8.encode(cred);
    var base64Str = base64.encode(bytes);
    var headers = {
      'Authorization': 'Basic $base64Str',
      'Accept': 'application/json'
    };
    var body = {
      'From': 'whatsapp:' + twilioWhatsappNumber,
      'To': 'whatsapp:' + recipientNumber,
      'Body': 'Your request code is ' + message
    };
    http.Response response = await http.post(url, headers: headers, body: body);
    print(response);
    if (response.statusCode == 201) {
      print('Sending success');
    } else {
      print('Sending Failed');
      var data = jsonDecode(response.body);
      print('Error Codde : ' + data['code'].toString());
      print('Error Message : ' + data['message']);
      print("More info : " + data['more_info']);
    }
  }

  Future<String> getFinanceData(String url) async {
    http.Response response = await http.get(url);
    print(response);
    if (response.statusCode == 200) {
      return response.body;
    } else {
      return '{"finance_interest_rate":"12"}';
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
        future: MyApp().getCacheData(),
        builder: (context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData) {
            Map<String, dynamic> jsonMap = jsonDecode(snapshot.data);
            var page = jsonMap['mobile'] != null ? MyHomePage(title: appName, name: jsonMap['name'], mobile: jsonMap['mobile'], tab: 0) : LoginPage(title: appName);
            return MaterialApp(
              title: appName,
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                primarySwatch: Colors.teal,
                scaffoldBackgroundColor: Colors.teal[50],
                visualDensity: VisualDensity.adaptivePlatformDensity,
              ),
              home: page,
            );
          } else {
            return MaterialApp(
              title: appName,
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                primarySwatch: Colors.teal,
                visualDensity: VisualDensity.adaptivePlatformDensity,
              ),
              home: LoadingPage(),
            );
          }
        }
    );
  }
}

class LoadingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: Container(
                child: Text('Loading..')
            )
        )
    );
  }
}

class LoginPage extends StatefulWidget {
  LoginPage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController(text: '');
  TextEditingController mobileController = TextEditingController(text: '+91');
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Center(
        child: SingleChildScrollView(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(widget.title, style: TextStyle(fontSize: 20)),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    child: Text('Please enter name and mobile number'),
                  ),
                  Container(
                      padding: const EdgeInsets.all(20.0),
                      child: Form(
                          key: _formKey,
                          child: Column(
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: <Widget> [
                                    Flexible(
                                      child: TextFormField(
                                        controller: nameController,
                                        decoration: InputDecoration(
                                          enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)
                                          ),
                                          labelText: 'Name',
                                        ),
                                        validator: (value) {
                                          if (value.isEmpty) {
                                            return 'Please enter the name';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    IconButton(icon: Icon(Icons.person, color: Theme.of(context).colorScheme.primary), onPressed: null),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: <Widget> [
                                    Flexible(
                                      child: TextFormField(
                                        controller: mobileController,
                                        decoration: InputDecoration(
                                          enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)
                                          ),
                                          labelText: 'Mobile',
                                        ),
                                        validator: (value) {
                                          if (value.isEmpty || (value.length == 3 && value.contains('+91')) || value.length != 13) {
                                            return 'Please enter the valid mobile number';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    IconButton(icon: Icon(Icons.phone, color: Theme.of(context).colorScheme.primary), onPressed: null),
                                  ],
                                ),
                              ),
                              SizedBox(
                                  height: 10
                              ),
                              RaisedButton(
                                  onPressed: () async {
                                    if (_formKey.currentState.validate()) {
                                      var file = await MyApp().getCacheFile();
                                      file.writeAsString('{"name":"'+nameController.text+'","mobile":"'+mobileController.text+'"}', flush: true, mode: FileMode.write);
                                      Navigator.push(context, MaterialPageRoute(
                                          builder: (_) => MyHomePage(
                                              title: widget.title,
                                              name: nameController.text,
                                              mobile: mobileController.text,
                                              tab: 0
                                          )
                                      ));
                                    }
                                  },
                                  color: Theme.of(context).colorScheme.primary,
                                  child: Text("Continue")
                              ),
                            ],
                          )
                      )
                  ),
                ]
            )
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title, this.name, this.mobile, this.tab}) : super(key: key);
  final String title;
  final String name;
  final String mobile;
  final int tab;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(vsync: this, length: 3, initialIndex: widget.tab);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController (
        length: 3,
        child: Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: Text(widget.title, style: TextStyle(fontSize: 14)),
            leading: IconButton(
                icon: Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState.openDrawer()
            ),
            actions: [
              IconButton(icon: Icon(Icons.notifications), onPressed: (){
                _scaffoldKey.currentState.showSnackBar(
                    SnackBar(
                        content: Text('No notification')
                    )
                );
              }),
              IconButton(icon: Icon(Icons.subdirectory_arrow_right), onPressed: () async {
                // clear cache
                await MyApp().removeCacheFile();
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => LoginPage(
                        title: widget.title
                    )
                ));
              }),
            ],
            bottom: TabBar(
                controller: tabController,
                tabs: <Widget> [
                  Tab(icon: Icon(CustomIcons.finance, size: 30), text: 'Finance'),
                  Tab(icon: Icon(CustomIcons.insurance, size: 30), text: 'Insurance'),
                  Tab(icon: Icon(CustomIcons.deposit, size: 30), text: 'Deposit')
                ]
            ),
          ),
          body: TabBarView(
              controller: tabController,
              children: <Widget>[
                FinanceTab(),
                InsuranceTab(),
                DepositTab(),
              ]
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              switch(tabController.index) {
                case 0: {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (_) => FinanceApplicationForm(
                          name: widget.name,
                          mobile: widget.mobile
                      )
                  ));
                }
                break;
                case 1: {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (_) => InsuranceApplicationForm(
                          name: widget.name,
                          mobile: widget.mobile
                      )
                  ));
                }
                break;
                case 2: {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (_) => DepositApplicationForm(
                          name: widget.name,
                          mobile: widget.mobile
                      )
                  ));
                }
                break;
                default:
                  break;
              }
            },
            child: Center(
              child: Text('Apply Now', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          drawer: SizedBox(
            width: 200,
            child: Drawer(
              child: Column(
                children: [
                  Container(
                    child: UserAccountsDrawerHeader(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        border: null,
                      ),
                      accountName: Text('Hi ' + widget.name),
                      accountEmail: Text(widget.mobile),
                      currentAccountPicture: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Icon(Icons.person, color: Colors.black, size: 50),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.playlist_add_check, color: Theme.of(context).colorScheme.primary),
                    title: Text('Apply Status'),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ComingSoonPage()
                      ));
                    },
                  ),
                  Divider(color: Theme.of(context).colorScheme.primary),
                  ListTile(
                    leading: Icon(Icons.payment, color: Theme.of(context).colorScheme.primary),
                    title: Text('Payments'),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ComingSoonPage()
                      ));
                    },
                  ),
                  Divider(color: Theme.of(context).colorScheme.primary),
                  ListTile(
                    leading: Icon(Icons.contact_mail, color: Theme.of(context).colorScheme.primary),
                    title: Text('Contact Us'),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ComingSoonPage()
                      ));
                    },
                  ),
                  Divider(color: Theme.of(context).colorScheme.primary),
                  ListTile(
                    leading: Icon(Icons.cancel, color: Theme.of(context).colorScheme.primary),
                    title: Text('Cancel'),
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        )
    );
  }
}

class FinanceTab extends StatefulWidget {
  FinanceTab({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _FinanceTabState createState() => _FinanceTabState();
}

class _FinanceTabState extends State<FinanceTab> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Card(
            child: Container(
              height: 70,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                border: Border (
                  left: BorderSide(width: 5, color: Theme.of(context).colorScheme.primary),
                ),
              ),
              child: ListView (
                scrollDirection: Axis.horizontal,
                children: <Widget> [
                  Container(
                    alignment: Alignment.center,
                    width: 280,
                    child: Text('Get hassle-free financing for old and new commercial vehicles'),
                  ),
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(math.pi),
                    child: IconButton(icon: Icon(CustomIcons.truck_1, color: Theme.of(context).colorScheme.primary), onPressed: null),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 40,
            alignment: Alignment.topLeft,
            padding: const EdgeInsets.all(10.0),
            child: Text('Vehicle Types'),
          ),
          Container(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                Card(
                  child: Container(
                    width: 120,
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      border: Border (
                        left: BorderSide(width: 5, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    child: Container(
                        alignment: Alignment.center,
                        child: ListView(
                          children: <Widget>[
                            Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.rotationY(math.pi),
                              child: IconButton(icon: Icon(CustomIcons.truck, color: Theme.of(context).colorScheme.primary), onPressed: null),
                            ),
                            Text('Small & Light commercial vehicles', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w300))
                          ],
                        )
                    ),
                  ),
                ),
                Card(
                  child: Container(
                    width: 120,
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      border: Border (
                        left: BorderSide(width: 5, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    child: Container(
                        alignment: Alignment.center,
                        child: ListView(
                          children: <Widget>[
                            IconButton(icon: Icon(CustomIcons.truck_moving, color: Theme.of(context).colorScheme.primary), onPressed: null),
                            Text('Medium & heavy commercial vehicle', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w300))
                          ],
                        )
                    ),
                  ),
                ),
                Card(
                  child: Container(
                    width: 120,
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      border: Border (
                        left: BorderSide(width: 5, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    child: Container(
                        alignment: Alignment.center,
                        child: ListView(
                          children: <Widget>[
                            IconButton(iconSize: 30, icon: Icon(CustomIcons.tipper, color: Theme.of(context).colorScheme.primary), onPressed: null),
                            Text('Tippers and Specially-customized vehicles', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w300))
                          ],
                        )
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 40,
            alignment: Alignment.topLeft,
            padding: const EdgeInsets.all(10.0),
            child: Text('EMI Schedule'),
          ),
          Card(
            child: Container(
              height: 170,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(),
              child: Column (
                children: <Widget> [
                  Container(
                    padding: const EdgeInsets.all(2.0),
                    child: Table(
                      border: TableBorder(
                        top: BorderSide(width: 2, color: Theme.of(context).colorScheme.primary, style: BorderStyle.solid),
                        horizontalInside: BorderSide(width: 1, color: Theme.of(context).colorScheme.primary, style: BorderStyle.solid),
                        bottom: BorderSide(width: 2, color: Theme.of(context).colorScheme.primary, style: BorderStyle.solid),
                      ),
                      children: [
                        TableRow (
                          children: [
                            Container(
                              padding: EdgeInsets.all(5.0),
                              child: Text('Loan Amount', style: TextStyle(fontWeight: FontWeight.w500)),
                            ),
                            Container(
                              padding: EdgeInsets.all(5.0),
                              child: Text('EMI (3year)', style: TextStyle(fontWeight: FontWeight.w500)),
                            ),
                            Container(
                              padding: EdgeInsets.all(5.0),
                              child: Text('EMI (5year)', style: TextStyle(fontWeight: FontWeight.w500)),
                            ),
                            Container(
                              padding: EdgeInsets.all(5.0),
                              child: Text('EMI (7year)', style: TextStyle(fontWeight: FontWeight.w500)),
                            ),
                          ],
                        ),
                        TableRow (
                          children: [
                            Container(
                              padding: EdgeInsets.all(5.0),
                              child: Text('₹2 Lakh', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300)),
                            ),
                            Container(
                              padding: EdgeInsets.all(5.0),
                              child: Text('₹7,400', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300)),
                            ),
                            Container(
                              padding: EdgeInsets.all(5.0),
                              child: Text('₹4,800', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300)),
                            ),
                            Container(
                              padding: EdgeInsets.all(5.0),
                              child: Text('₹3,400', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300)),
                            ),
                          ],
                        ),
                        TableRow (
                          children: [
                            Container(
                              padding: EdgeInsets.all(5.0),
                              child: Text('₹3 lakh', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300)),
                            ),
                            Container(
                              padding: EdgeInsets.all(5.0),
                              child: Text('₹10,400', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300)),
                            ),
                            Container(
                              padding: EdgeInsets.all(5.0),
                              child: Text('₹5,600', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300)),
                            ),
                            Container(
                              padding: EdgeInsets.all(5.0),
                              child: Text('₹4,200', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300)),
                            ),
                          ],
                        ),
                        TableRow (
                          children: [
                            Container(
                              padding: EdgeInsets.all(5.0),
                              child: Text('₹5 lakh', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300)),
                            ),
                            Container(
                              padding: EdgeInsets.all(5.0),
                              child: Text('₹15,200', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300)),
                            ),
                            Container(
                              padding: EdgeInsets.all(5.0),
                              child: Text('₹9,800', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300)),
                            ),
                            Container(
                              padding: EdgeInsets.all(5.0),
                              child: Text('₹7,200', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 40,
            alignment: Alignment.topLeft,
            padding: const EdgeInsets.all(10.0),
            child: Text('Features & Benefits'),
          ),
          Container(
            height: 160,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                Card(
                  child: Container(
                    width: 150,
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      border: Border (
                        left: BorderSide(width: 5, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: ListView(
                        scrollDirection: Axis.vertical,
                        children: <Widget>[
                          IconButton(icon: Icon(CustomIcons.rupee, color: Theme.of(context).colorScheme.primary), onPressed: null),
                          Text('FINANCE UP TO 100% ON VALUE', textAlign: TextAlign.center),
                          SizedBox(height: 5),
                          Text('Finance up to 100% on chassis value and 90% on fully build vehicles', textAlign: TextAlign.center, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w300)),
                        ],
                      ),
                    ),
                  ),
                ),
                Card(
                  child: Container(
                    width: 150,
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      border: Border (
                        left: BorderSide(width: 5, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: ListView(
                        scrollDirection: Axis.vertical,
                        children: <Widget>[
                          IconButton(icon: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary), onPressed: null),
                          Text('FINANCE UP TO 15 YEARS', textAlign: TextAlign.center),
                          SizedBox(height: 5),
                          Text('Finance up to 15 years for commercial vehicles', textAlign: TextAlign.center, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w300)),
                        ],
                      ),
                    ),
                  ),
                ),
                Card(
                  child: Container(
                    width: 150,
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      border: Border (
                        left: BorderSide(width: 5, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: ListView(
                        scrollDirection: Axis.vertical,
                        children: <Widget>[
                          IconButton(icon: Icon(Icons.description, color: Theme.of(context).colorScheme.primary), onPressed: null),
                          Text('QUICK PROCESS', textAlign: TextAlign.center),
                          SizedBox(height: 5),
                          Text('Faster valuation and Speedy disbursement', textAlign: TextAlign.center, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w300)),
                        ],
                      ),
                    ),
                  ),
                ),
                Card(
                  child: Container(
                    width: 150,
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      border: Border (
                        left: BorderSide(width: 5, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: ListView(
                        scrollDirection: Axis.vertical,
                        children: <Widget>[
                          IconButton(icon: Icon(Icons.payment, color: Theme.of(context).colorScheme.primary), onPressed: null),
                          Text('FLEXIBLE REPAYMENT', textAlign: TextAlign.center),
                          SizedBox(height: 5),
                          Text('Enabling borrowers to pay off EMI without any burden', textAlign: TextAlign.center, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w300)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
              height: 40
          ),
        ],
      ),
    );
  }
}

class FinanceApplicationForm extends StatefulWidget {
  FinanceApplicationForm({Key key, this.name, this.mobile}) : super(key: key);
  final String name;
  final String mobile;
  @override
  _FinanceApplicationFormState createState() => _FinanceApplicationFormState();
}

class _FinanceApplicationFormState extends State<FinanceApplicationForm> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  TextEditingController othersController = TextEditingController(text: '');
  TextEditingController amountController = TextEditingController(text: '');
  TextEditingController remarksController = TextEditingController(text: '');
  String selectedCity = 'Bengaluru';
  String selectedVehicleType = 'Select';
  @override
  Widget build(BuildContext context) {
    var config = AppConfig.of(context);
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Finance Application Form', style: TextStyle(fontSize: 14)),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget> [
                    Flexible(
                      child: DropdownButtonFormField<String>(
                        value: selectedCity,
                        decoration: InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)
                          ),
                          labelText: 'City',
                        ),
                        onChanged: (String changedCity) {
                          setState(() {
                            selectedCity = changedCity;
                          });
                        },
                        items: <String>['Bengaluru', 'Mysuru', 'Kolar']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                    IconButton(icon: Icon(Icons.location_city, color: Theme.of(context).colorScheme.primary), onPressed: null),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget> [
                    Flexible(
                      child: DropdownButtonFormField<String>(
                        value: selectedVehicleType,
                        decoration: InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)
                          ),
                          labelText: 'Vehicle Model*',
                        ),
                        onChanged: (String changedVehicleType) {
                          setState(() => selectedVehicleType = changedVehicleType);
                        },
                        items: <String>['Select','Tata Ace','Tata 407','Tata 912LPK','Mahindra Jeeto','Mahindra Jayo','Ashok Leyland Dost','Ashol Leyland Partner','Ashok Leyland 1920','Eicher Pro','Bharat Benz 1923','Others']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        validator: (value) {
                          if (value.contains('Select')) {
                            return 'Please select the vehicle model';
                          }
                          return null;
                        },
                      ),
                    ),
                    IconButton(icon: Icon(CustomIcons.truck, color: Theme.of(context).colorScheme.primary), onPressed: null),
                  ],
                ),
              ),
              selectedVehicleType.contains('Others') ? Container(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget> [
                    Flexible(
                      child: TextFormField(
                        controller: othersController,
                        decoration: InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)
                          ),
                          labelText: 'Others*',
                        ),
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'Please enter the vehicle model';
                          }
                          return null;
                        },
                      ),
                    ),
                    IconButton(icon: Icon(CustomIcons.truck, color: Theme.of(context).colorScheme.primary), onPressed: null),
                  ],
                ),
              ) : SizedBox(),
              Container(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget> [
                    Flexible(
                      child: TextFormField(
                        controller: amountController,
                        decoration: InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)
                          ),
                          labelText: 'Loan Amount',
                        ),
                      ),
                    ),
                    IconButton(icon: Icon(CustomIcons.rupee, color: Theme.of(context).colorScheme.primary), onPressed: null),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget> [
                    Flexible(
                      child: TextFormField(
                        controller: remarksController,
                        decoration: InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)
                          ),
                          labelText: 'Remarks',
                        ),
                      ),
                    ),
                    IconButton(icon: Icon(Icons.description, color: Theme.of(context).colorScheme.primary), onPressed: null),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8.0),
                child: RaisedButton(
                  onPressed: () async {
                    if (_formKey.currentState.validate()) {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return LoadingDialog();
                          }
                      );
                      String message = ': [FINANCE REQUEST] ';
                      message = message + 'Name: ' + widget.name + ', ';
                      message = message + 'Phone #: ' + widget.mobile + ', ';
                      message = message + 'City: ' + selectedCity + ', ';
                      message = message + 'Vehicle: ' + (selectedVehicleType.contains('Others') ? othersController.text : selectedVehicleType) + ', ';
                      message = message + 'Loan Amount: ' + (amountController.text.isEmpty ? 'none' : amountController.text) + ', ';
                      message = message + 'Remarks: ' + (remarksController.text.isEmpty ? 'none' : remarksController.text);
                      await MyApp().sendWhatsApp(config.twilioBaseUrl, config.twilioAccountSid, config.twilioApikeySid, config.twilioSecret, config.twilioWhatsappNumber, config.recipientNumber, message);
                      Navigator.of(context).pop();
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return SubmitDialog(name: widget.name, mobile: widget.mobile, tab: 0);
                          }
                      );
                    }
                  },
                  child: Text("Apply"),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InsuranceTab extends StatefulWidget {
  InsuranceTab({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _InsuranceTabState createState() => _InsuranceTabState();
}

class _InsuranceTabState extends State<InsuranceTab> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Card(
            child: Container(
              height: 70,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                border: Border (
                  left: BorderSide(width: 5, color: Theme.of(context).colorScheme.primary),
                ),
              ),
              child: ListView (
                scrollDirection: Axis.horizontal,
                children: <Widget> [
                  Container(
                    alignment: Alignment.center,
                    width: 280,
                    child: Text('Extensive coverage to protect your vehicle from every risk.'),
                  ),
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(math.pi),
                    child: IconButton(icon: Icon(CustomIcons.truck_1, color: Theme.of(context).colorScheme.primary), onPressed: null),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 40,
            alignment: Alignment.topLeft,
            padding: const EdgeInsets.all(10.0),
            child: Text('Features & Benefits'),
          ),
          Container(
            height: 150,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                Card(
                  child: Container(
                    width: 150,
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      border: Border (
                        left: BorderSide(width: 5, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: ListView(
                        scrollDirection: Axis.vertical,
                        children: <Widget>[
                          IconButton(iconSize: 30, icon: Icon(CustomIcons.earthquake, color: Theme.of(context).colorScheme.primary), onPressed: null),
                          Text('Coverage against flood, earthquake, landslide, etc.,', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
                Card(
                  child: Container(
                    width: 150,
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      border: Border (
                        left: BorderSide(width: 5, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: ListView(
                        scrollDirection: Axis.vertical,
                        children: <Widget>[
                          IconButton(iconSize: 40, icon: Icon(CustomIcons.accident, color: Theme.of(context).colorScheme.primary), onPressed: null),
                          Text('Coverage against accidental external damage, theft, etc.,', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
                Card(
                  child: Container(
                    width: 150,
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      border: Border (
                        left: BorderSide(width: 5, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: ListView(
                        scrollDirection: Axis.vertical,
                        children: <Widget>[
                          IconButton(icon: Icon(Icons.description, color: Theme.of(context).colorScheme.primary), onPressed: null),
                          Text('Zero depreciation cover', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
                Card(
                  child: Container(
                    width: 150,
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      border: Border (
                        left: BorderSide(width: 5, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: ListView(
                        scrollDirection: Axis.vertical,
                        children: <Widget>[
                          IconButton(icon: Icon(CustomIcons.by_24_7, color: Theme.of(context).colorScheme.primary), onPressed: null),
                          Text('24X7 on road side assistance coverage', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 40,
            alignment: Alignment.topLeft,
            padding: const EdgeInsets.all(10.0),
            child: Text('Other Insurances'),
          ),
          Container(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                Card(
                  child: Container(
                    width: 150,
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      border: Border (
                        left: BorderSide(width: 5, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    child: Container(
                        alignment: Alignment.center,
                        child: ListView(
                          children: <Widget>[
                            Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.rotationY(math.pi),
                              child: IconButton(iconSize: 30, icon: Icon(CustomIcons.lifeinsurance, color: Theme.of(context).colorScheme.primary), onPressed: null),
                            ),
                            Text('Life Insurance', textAlign: TextAlign.center, style: TextStyle(fontSize: 12))
                          ],
                        )
                    ),
                  ),
                ),
                Card(
                  child: Container(
                    width: 150,
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      border: Border (
                        left: BorderSide(width: 5, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    child: Container(
                        alignment: Alignment.center,
                        child: ListView(
                          children: <Widget>[
                            IconButton(icon: Icon(CustomIcons.medicalinsurance, color: Theme.of(context).colorScheme.primary), onPressed: null),
                            Text('Health Insurance', textAlign: TextAlign.center, style: TextStyle(fontSize: 12))
                          ],
                        )
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
              height: 40
          ),
        ],
      ),
    );
  }
}

class InsuranceApplicationForm extends StatefulWidget {
  InsuranceApplicationForm({Key key, this.name, this.mobile}) : super(key: key);
  final String name;
  final String mobile;
  @override
  _InsuranceApplicationFormState createState() => _InsuranceApplicationFormState();
}

class _InsuranceApplicationFormState extends State<InsuranceApplicationForm> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  TextEditingController vehicleController = TextEditingController(text: '');
  TextEditingController remarksController = TextEditingController(text: '');
  String selectedCity = 'Bengaluru';
  String selectedInsuranceType = 'Select';
  @override
  Widget build(BuildContext context) {
    var config = AppConfig.of(context);
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Insurance Application Form', style: TextStyle(fontSize: 14)),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget> [
                    Flexible(
                      child: DropdownButtonFormField<String>(
                        value: selectedCity,
                        decoration: InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)
                          ),
                          labelText: 'City',
                        ),
                        onChanged: (String changedCity) {
                          setState(() {
                            selectedCity = changedCity;
                          });
                        },
                        items: <String>['Bengaluru', 'Mysuru', 'Kolar']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                    IconButton(icon: Icon(Icons.location_city, color: Theme.of(context).colorScheme.primary), onPressed: null),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget> [
                    Flexible(
                      child: DropdownButtonFormField<String>(
                        value: selectedInsuranceType,
                        decoration: InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)
                          ),
                          labelText: 'Insurance Type*',
                        ),
                        onChanged: (String changedInsuranceType) {
                          setState(() => selectedInsuranceType = changedInsuranceType);
                        },
                        items: <String>['Select','Vehicle Insurance','Life Insurance','Health Insurance']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        validator: (value) {
                          if (value.contains('Select')) {
                            return 'Please select the Insurance Type';
                          }
                          return null;
                        },
                      ),
                    ),
                    IconButton(icon: Icon(CustomIcons.insurance, color: Theme.of(context).colorScheme.primary), onPressed: null),
                  ],
                ),
              ),
              selectedInsuranceType.contains('Vehicle Insurance') ? Container(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget> [
                    Flexible(
                      child: TextFormField(
                        controller: vehicleController,
                        decoration: InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)
                          ),
                          labelText: 'Vehicle Registration Number*',
                        ),
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'Please enter the vehicle registration number';
                          }
                          return null;
                        },
                      ),
                    ),
                    IconButton(icon: Icon(CustomIcons.truck, color: Theme.of(context).colorScheme.primary), onPressed: null),
                  ],
                ),
              ) : SizedBox(),
              Container(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget> [
                    Flexible(
                      child: TextFormField(
                        controller: remarksController,
                        decoration: InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)
                          ),
                          labelText: 'Remarks',
                        ),
                      ),
                    ),
                    IconButton(icon: Icon(Icons.description, color: Theme.of(context).colorScheme.primary), onPressed: null),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8.0),
                child: RaisedButton(
                  onPressed: () async {
                    if (_formKey.currentState.validate()) {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return LoadingDialog();
                          }
                      );
                      String message = ': [INSURANCE REQUEST] ';
                      message = message + 'Name: ' + widget.name + ', ';
                      message = message + 'Phone #: ' + widget.mobile + ', ';
                      message = message + 'City: ' + selectedCity + ', ';
                      message = message + 'Insurance Type: ' + selectedInsuranceType + ', ';
                      message = message + (selectedInsuranceType.contains('Vehicle Insurance') ? 'Vehicle Registration Number: ' + vehicleController.text + ', ': '');
                      message = message + 'Remarks: ' + (remarksController.text.isEmpty ? 'none' : remarksController.text);
                      await MyApp().sendWhatsApp(config.twilioBaseUrl, config.twilioAccountSid, config.twilioApikeySid, config.twilioSecret, config.twilioWhatsappNumber, config.recipientNumber, message);
                      Navigator.of(context).pop();
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return SubmitDialog(name: widget.name, mobile: widget.mobile, tab: 1);
                          }
                      );
                    }
                  },
                  child: Text("Apply"),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DepositTab extends StatefulWidget {
  DepositTab({Key key, this.mobile}) : super(key: key);
  final String mobile;
  @override
  _DepositTabState createState() => _DepositTabState();
}

class _DepositTabState extends State<DepositTab> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Card(
            child: Container(
              height: 70,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                border: Border (
                  left: BorderSide(width: 5, color: Theme.of(context).colorScheme.primary),
                ),
              ),
              child: ListView (
                scrollDirection: Axis.horizontal,
                children: <Widget> [
                  Container(
                    alignment: Alignment.center,
                    width: 280,
                    child: Text('Invest in our deposit products, grow your wealth! '),
                  ),
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(math.pi),
                    child: IconButton(icon: Icon(CustomIcons.truck_1, color: Theme.of(context).colorScheme.primary), onPressed: null),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 40,
            alignment: Alignment.topLeft,
            padding: const EdgeInsets.all(10.0),
            child: Text('Deposit Products'),
          ),
          Container(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                Card(
                  child: Container(
                    width: 150,
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      border: Border (
                        left: BorderSide(width: 5, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    child: Container(
                        alignment: Alignment.center,
                        child: ListView(
                          children: <Widget>[
                            Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.rotationY(math.pi),
                              child: IconButton(iconSize: 30, icon: Icon(CustomIcons.debenture, color: Theme.of(context).colorScheme.primary), onPressed: null),
                            ),
                            Text('Debenture', textAlign: TextAlign.center, style: TextStyle(fontSize: 12))
                          ],
                        )
                    ),
                  ),
                ),
                Card(
                  child: Container(
                    width: 150,
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      border: Border (
                        left: BorderSide(width: 5, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    child: Container(
                        alignment: Alignment.center,
                        child: ListView(
                          children: <Widget>[
                            IconButton(iconSize: 35, icon: Icon(CustomIcons.deposit, color: Theme.of(context).colorScheme.primary), onPressed: null),
                            Text('Deposit', textAlign: TextAlign.center, style: TextStyle(fontSize: 12))
                          ],
                        )
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
              height: 40
          ),
        ],
      ),
    );
  }
}

class DepositApplicationForm extends StatefulWidget {
  DepositApplicationForm({Key key, this.name, this.mobile}) : super(key: key);
  final String name;
  final String mobile;
  @override
  _DepositApplicationFormState createState() => _DepositApplicationFormState();
}

class _DepositApplicationFormState extends State<DepositApplicationForm> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  TextEditingController amountController = TextEditingController(text: '');
  TextEditingController remarksController = TextEditingController(text: '');
  String selectedCity = 'Bengaluru';
  String selectedProductType = 'Select';
  @override
  Widget build(BuildContext context) {
    var config = AppConfig.of(context);
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Deposit Application Form', style: TextStyle(fontSize: 14)),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget> [
                    Flexible(
                      child: DropdownButtonFormField<String>(
                        value: selectedCity,
                        decoration: InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)
                          ),
                          labelText: 'City',
                        ),
                        onChanged: (String changedCity) {
                          setState(() {
                            selectedCity = changedCity;
                          });
                        },
                        items: <String>['Bengaluru', 'Mysuru', 'Kolar']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                    IconButton(icon: Icon(Icons.location_city, color: Theme.of(context).colorScheme.primary), onPressed: null),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget> [
                    Flexible(
                      child: DropdownButtonFormField<String>(
                        value: selectedProductType,
                        decoration: InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)
                          ),
                          labelText: 'Product*',
                        ),
                        onChanged: (String changedProductType) {
                          setState(() => selectedProductType = changedProductType);
                        },
                        items: <String>['Select','Debenture','Deposit']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        validator: (value) {
                          if (value.contains('Select')) {
                            return 'Please select the product';
                          }
                          return null;
                        },
                      ),
                    ),
                    IconButton(icon: Icon(CustomIcons.deposit, color: Theme.of(context).colorScheme.primary), onPressed: null),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget> [
                    Flexible(
                      child: TextFormField(
                        controller: amountController,
                        decoration: InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)
                          ),
                          labelText: 'Investment Amount',
                        ),
                      ),
                    ),
                    IconButton(icon: Icon(CustomIcons.rupee, color: Theme.of(context).colorScheme.primary), onPressed: null),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget> [
                    Flexible(
                      child: TextFormField(
                        controller: remarksController,
                        decoration: InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)
                          ),
                          labelText: 'Remarks',
                        ),
                      ),
                    ),
                    IconButton(icon: Icon(Icons.description, color: Theme.of(context).colorScheme.primary), onPressed: null),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8.0),
                child: RaisedButton(
                  onPressed: () async {
                    if (_formKey.currentState.validate()) {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return LoadingDialog();
                          }
                      );
                      String message = ': [DEPOSIT REQUEST] ';
                      message = message + 'Name: ' + widget.name + ', ';
                      message = message + 'Phone #: ' + widget.mobile + ', ';
                      message = message + 'City: ' + selectedCity + ', ';
                      message = message + 'Product: ' + selectedProductType + ', ';
                      message = message + 'Investment Amount: ' + (amountController.text.isEmpty ? 'none' : amountController.text) + ', ';
                      message = message + 'Remarks: ' + (remarksController.text.isEmpty ? 'none' : remarksController.text);
                      await MyApp().sendWhatsApp(config.twilioBaseUrl, config.twilioAccountSid, config.twilioApikeySid, config.twilioSecret, config.twilioWhatsappNumber, config.recipientNumber, message);
                      Navigator.of(context).pop();
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return SubmitDialog(name: widget.name, mobile: widget.mobile, tab: 2);
                          }
                      );
                    }
                  },
                  child: Text("Apply"),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoadingDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0)
      ), //this right here
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(12.0),
        child: Center(
          child: Column(
            children: [
              SizedBox(
                  height: 70
              ),
              Text('Submitting..')
            ],
          ),
        ),
      ),
    );
  }
}

class SubmitDialog extends StatefulWidget {
  SubmitDialog({Key key, this.name, this.mobile, this.tab}) : super(key: key);
  final String name;
  final String mobile;
  final int tab;

  @override
  _SubmitDialogState createState() => _SubmitDialogState();
}

class _SubmitDialogState extends State<SubmitDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0)
      ), //this right here
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(12.0),
        child: Center(
          child: Column(
            children: [
              SizedBox(
                  height: 40
              ),
              Text('Thanks for providing us the details. Our representative will contact you'),
              SizedBox(
                  height: 20
              ),
              RaisedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                        builder: (_) => MyHomePage(
                          title: MyApp.appName,
                          name: widget.name,
                          mobile: widget.mobile,
                          tab: widget.tab,
                        )
                    ));
                  },
                  child: Text('Ok'),
                  color: Theme.of(context).colorScheme.primary
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ComingSoonPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Go Back', style: TextStyle(fontSize: 14)),
        ),
        body: Center(
            child: Container(
                child: Text('Coming Soon')
            )
        )
    );
  }
}