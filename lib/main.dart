import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/rendering.dart';
import 'package:flutter/gestures.dart';
import 'package:http/http.dart' as http;
import 'dart:math' show pi,pow;
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
    if (response.statusCode == 201) {
      print('Sending success');
    } else {
      print('Sending Failed');
      var data = jsonDecode(response.body);
      print('Error Code : ' + data['code'].toString());
      print('Error Message : ' + data['message']);
      print("More info : " + data['more_info']);
    }
  }
  Future<String> getHttpData(String url) async {
    http.Response response = await http.get(url);
    if (response.statusCode == 200) {
      return response.body;
    } else {
      return '{"finance_interest_rate":"12"}';
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    Widget widget;
    if (kIsWeb) {
      widget = MaterialApp(
        title: appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.teal,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: LoginPage(title: appName),
      );
    } else {
      if (Platform.isAndroid) {
        widget = FutureBuilder<String>(
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
      } else if (Platform.isIOS) {
        widget = MaterialApp(
          title: appName,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.teal,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: LoginPage(title: appName),
        );
      }
    }
    return widget;
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
                                      if (!kIsWeb && Platform.isAndroid) {
                                        var file = await MyApp().getCacheFile();
                                        file.writeAsString('{"name":"'+nameController.text+'","mobile":"'+mobileController.text+'"}', flush: true, mode: FileMode.write);
                                      }
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
              IconButton(icon: Icon(CustomIcons.logout, size:16), onPressed: () async {
                if (!kIsWeb && Platform.isAndroid) {
                  await MyApp().removeCacheFile();
                }
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
                FinanceTab(
                  name: widget.name,
                  mobile: widget.mobile
                ),
                InsuranceTab(
                  name: widget.name,
                  mobile: widget.mobile
                ),
                DepositTab(
                  name: widget.name,
                  mobile: widget.mobile
                ),
              ]
          ),
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
                    leading: Icon(CustomIcons.features, color: Theme.of(context).colorScheme.primary),
                    title: Text('Features'),
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
  FinanceTab({Key key, this.name, this.mobile}) : super(key: key);
  final String name;
  final String mobile;
  @override
  _FinanceTabState createState() => _FinanceTabState();
}

class _FinanceTabState extends State<FinanceTab> {
  @override
  Widget build(BuildContext context) {
    var config = AppConfig.of(context);
    return FutureBuilder<String>(
      future: MyApp().getHttpData(config.financeUrl),
      builder: (context, AsyncSnapshot<String> snapshot) {
        Widget segments;
        if (snapshot.hasData) {
          Map<String, dynamic> jsonMap = jsonDecode(snapshot.data);
          List<dynamic> vehicleSegments = jsonMap['VEHICLE SEGMENTS'];
          segments = Container(
            height: 360,
            child: GridView.count(
                crossAxisCount: 3,
                scrollDirection: Axis.vertical,
                children: List.generate(vehicleSegments.length,(index) {
                  Icon segmentIcon;
                  if(vehicleSegments[index]['NAME'].toString().contains('CONSTRUCTION VEHICLE')) {
                    segmentIcon = Icon(CustomIcons.constructionvehicle, size: 50, color: Theme.of(context).colorScheme.primary);
                  } else if(vehicleSegments[index]['NAME'].toString().contains('FARM EQUIPMENT')) {
                    segmentIcon = Icon(CustomIcons.farmequipment, size: 30, color: Theme.of(context).colorScheme.primary);
                  } else if(vehicleSegments[index]['NAME'].toString().contains('LCV')) {
                    segmentIcon = Icon(CustomIcons.lcv, size: 50, color: Theme.of(context).colorScheme.primary);
                  } else if(vehicleSegments[index]['NAME'].toString().contains('MACHINERY')) {
                    segmentIcon = Icon(CustomIcons.machinery, size: 50, color: Theme.of(context).colorScheme.primary);
                  } else if(vehicleSegments[index]['NAME'].toString().contains('MHCV')) {
                    segmentIcon = Icon(CustomIcons.mhcv, size: 40, color: Theme.of(context).colorScheme.primary);
                  } else if(vehicleSegments[index]['NAME'].toString().contains('PASSENGER 3WHEELER')) {
                    segmentIcon = Icon(CustomIcons.threewheeler, size: 30, color: Theme.of(context).colorScheme.primary);
                  } else if(vehicleSegments[index]['NAME'].toString().contains('PASSENGER COMMERCIAL')) {
                    segmentIcon = Icon(CustomIcons.passengercommercial, size: 40, color: Theme.of(context).colorScheme.primary);
                  } else if(vehicleSegments[index]['NAME'].toString().contains('PRIVATE CAR')) {
                    segmentIcon = Icon(CustomIcons.privatecar, size: 50, color: Theme.of(context).colorScheme.primary);
                  } else if(vehicleSegments[index]['NAME'].toString().contains('TWO WHEELER')) {
                    segmentIcon = Icon(CustomIcons.twowheeler, size: 50, color: Theme.of(context).colorScheme.primary);
                  } else {
                    segmentIcon = Icon(CustomIcons.truck, color: Theme.of(context).colorScheme.primary);
                  }
                  return Container(
                    child: Card(
                      elevation: 3.0,
                      shape: RoundedRectangleBorder(
                        borderRadius : BorderRadius.all(Radius.circular(5)),
                        side: BorderSide(width: 1, color: Theme.of(context).colorScheme.primary)
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Text(vehicleSegments[index]['NAME'], textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
                            Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.rotationY(pi),
                              child: IconButton(icon: segmentIcon, onPressed: () {
                                Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => FinanceApplicationForm(
                                        name: widget.name,
                                        mobile: widget.mobile,
                                        vehiclesegmentindex: index,
                                        vehiclesegment: vehicleSegments[index]['NAME']
                                    )
                                ));
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                })
            ),
          );
        } else {
          segments = SizedBox(
            height: 40,
            child: Center(
              child: Container(
                child: Text('Loading..')
              )
            )
          );
        }
        return SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius : BorderRadius.all(Radius.circular(5)),
                ),
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
                        transform: Matrix4.rotationY(pi),
                        child: IconButton(icon: Icon(CustomIcons.truck, color: Theme.of(context).colorScheme.primary), onPressed: null),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                height: 40,
                alignment: Alignment.topLeft,
                padding: const EdgeInsets.all(10.0),
                child: Text('Vehicle Segments'),
              ),
              segments
            ],
          ),
        );
      }
    );
  }
}

class FinanceApplicationForm extends StatefulWidget {
  FinanceApplicationForm({Key key, this.name, this.mobile, this.vehiclesegmentindex, this.vehiclesegment}) : super(key: key);
  final String name;
  final String mobile;
  final int vehiclesegmentindex;
  final String vehiclesegment;
  @override
  _FinanceApplicationFormState createState() => _FinanceApplicationFormState();
}

class _FinanceApplicationFormState extends State<FinanceApplicationForm> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  TextEditingController othersController = TextEditingController(text: '');
  TextEditingController amountController = TextEditingController(text: '');
  String selectedCity = 'Bengaluru';
  String selectedVehicleName = 'Select';
  String selectedManufacturer = 'Select';
  FocusNode myFocusNode;

  @override
  void initState() {
    super.initState();
    myFocusNode = FocusNode();
  }

  @override
  void dispose() {
    myFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var config = AppConfig.of(context);
    return FutureBuilder<String>(
      future: MyApp().getHttpData(config.financeUrl),
      builder: (context, AsyncSnapshot<String> snapshot) {
        Set<String> uniqueManufacturers = Set();
        Set<String> uniqueVehicleNames = Set();
        List<String> manufacturers = <String>['Select','Loading..'];
        List<String> vehiclenames = <String>['Select'];
        if (snapshot.hasData) {
          Map<String, dynamic> jsonMap = jsonDecode(snapshot.data);
          List<dynamic> vehicleSegmentsDetails = jsonMap['VEHICLE SEGMENTS'][widget.vehiclesegmentindex]['DETAILS'];
          List.generate(vehicleSegmentsDetails.length, (index) {
            uniqueManufacturers.add(vehicleSegmentsDetails[index]['MANUFACTURER']);
            if (selectedManufacturer.contains(vehicleSegmentsDetails[index]['MANUFACTURER'])) {
              uniqueVehicleNames.add(vehicleSegmentsDetails[index]['ASSET DESCRIPTION']);
            }
          });
          manufacturers.removeAt(1);
          manufacturers.addAll(uniqueManufacturers);
          if (!selectedManufacturer.contains('Select')) {
            uniqueVehicleNames.add('Others');
          }
          vehiclenames.addAll(uniqueVehicleNames);
        }
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
                          child: TextFormField(
                            initialValue: widget.vehiclesegment,
                            readOnly: true,
                            decoration: InputDecoration(
                              enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)
                              ),
                              labelText: 'Vehicle Segment',
                            ),
                          ),
                        ),
                        IconButton(icon: Icon(CustomIcons.truck, color: Theme.of(context).colorScheme.primary), onPressed: null),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: <Widget> [
                        Flexible(
                          child: AbsorbPointer(
                            absorbing: selectedVehicleName.contains('Select') ? false : true,
                            child: DropdownButtonFormField<String>(
                              value: selectedManufacturer,
                              decoration: InputDecoration(
                                enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)
                                ),
                                labelText: 'Manufacturer Name*',
                              ),
                              onChanged: (String changedManufacturer) {
                                setState(() {
                                  if(!changedManufacturer.contains('Loading..')) {
                                    selectedManufacturer = changedManufacturer;
                                  }
                                });
                              },
                              items: manufacturers
                                  .map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              validator: (value) {
                                if (value.contains('Select')) {
                                  return 'Please select the manufacturer name';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        IconButton(icon: Icon(CustomIcons.truck, color: Theme.of(context).colorScheme.primary), onPressed: null),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: <Widget> [
                        Flexible(
                          child: DropdownButtonFormField<String>(
                            value: selectedVehicleName,
                            decoration: InputDecoration(
                              enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)
                              ),
                              labelText: 'Vehicle Name*',
                            ),
                            onChanged: (String changedVehicleName) {
                              setState(() => selectedVehicleName = changedVehicleName);
                            },
                            items: vehiclenames
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: value.length > 38 ? Text(value, style: TextStyle(fontSize: 6)) : value.length > 32 ? Text(value, style: TextStyle(fontSize: 8)) : value.length > 26 ? Text(value, style: TextStyle(fontSize: 10)) : Text(value, style: TextStyle(fontSize: 12))
                              );
                            }).toList(),
                            validator: (value) {
                              if (value.contains('Select')) {
                                return 'Please select the vehicle name';
                              }
                              return null;
                            },
                          ),
                        ),
                        IconButton(icon: Icon(CustomIcons.truck, color: Theme.of(context).colorScheme.primary), onPressed: null),
                      ],
                    ),
                  ),
                  selectedVehicleName.contains('Others') ? Container(
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
                                return 'Please enter the vehicle name';
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
                              labelText: 'Loan Amount*',
                            ),
                            validator: (value) {
                              if (value.isEmpty) {
                                return 'Please enter the loan amount';
                              } else if (!value.contains(RegExp(r'^[0-9]+$'))) {
                                return 'Please enter only the numbers';
                              }
                              return null;
                            },
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
                    child: RaisedButton(
                      onPressed: () async {
                        if (_formKey.currentState.validate()) {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return ShowEMIDialog(
                                    name: widget.name,
                                    mobile: widget.mobile,
                                    tab: 0,
                                    vehiclesegment: widget.vehiclesegment,
                                    manufacturer: selectedManufacturer,
                                    vehiclename: (selectedVehicleName.contains('Others') ? othersController.text : selectedVehicleName),
                                    loanamount: int.parse(amountController.text),
                                    city: selectedCity,
                                );
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
    );
  }
}

class InsuranceTab extends StatefulWidget {
  InsuranceTab({Key key, this.name, this.mobile}) : super(key: key);
  final String name;
  final String mobile;
  @override
  _InsuranceTabState createState() => _InsuranceTabState();
}

class _InsuranceTabState extends State<InsuranceTab> {
  bool vehicleInsurancePressed = false;
  bool vehicleSegmentsFetched = false;
  List<dynamic> vehicleSegments;
  @override
  Widget build(BuildContext context) {
    var config = AppConfig.of(context);
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Card(
            shape: RoundedRectangleBorder(
              borderRadius : BorderRadius.all(Radius.circular(5)),
            ),
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
                    transform: Matrix4.rotationY(pi),
                    child: IconButton(icon: Icon(CustomIcons.generalinsurance, color: Theme.of(context).colorScheme.primary), onPressed: null),
                  ),
                ],
              ),
            ),
          ),
          vehicleSegmentsFetched ?
          Container(
            height: 40,
            alignment: Alignment.topLeft,
            padding: const EdgeInsets.all(10.0),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Insurances',
                    style: TextStyle(decoration: TextDecoration.underline, fontSize: 16, color: Colors.blue),
                    recognizer: TapGestureRecognizer()..onTap = () {
                      setState(() {
                        vehicleSegmentsFetched = false;
                      });
                    }
                  ),
                  TextSpan(
                    text: ' > Vehicle Insurance > Segments',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ]
              )
            )
          ) :
          Container(
            height: 40,
            alignment: Alignment.topLeft,
            padding: const EdgeInsets.all(10.0),
            child: Text('Insurances Types'),
          ),
          vehicleSegmentsFetched ? SizedBox() :
          Container(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                Card(
                  child: Container(
                    width: 112,
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      border: Border (
                        top: BorderSide(width: 3, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    child: Container(
                        alignment: Alignment.center,
                        child: ListView(
                          children: <Widget>[
                            Text('Vehicle Insurance', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                            Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.rotationY(pi),
                              child: IconButton(
                                  iconSize: 30,
                                  icon: Icon(CustomIcons.vehicleinsurance, color: Theme.of(context).colorScheme.primary),
                                  onPressed: () async {
                                    setState(() {
                                      vehicleInsurancePressed = true;
                                    });
                                    String data = await MyApp().getHttpData(config.financeUrl);
                                    Map<String, dynamic> jsonMap = jsonDecode(data);
                                    setState(() {
                                      vehicleSegments = jsonMap['VEHICLE SEGMENTS'];
                                      vehicleSegmentsFetched = true;
                                      vehicleInsurancePressed = false;
                                    });
                                  }),
                            )
                          ],
                        )
                    ),
                  ),
                ),
                Card(
                  child: Container(
                    width: 112,
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      border: Border (
                        top: BorderSide(width: 3, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    child: Container(
                        alignment: Alignment.center,
                        child: ListView(
                          children: <Widget>[
                            Text('Life Insurance', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                            SizedBox(height: 10),
                            IconButton(
                                iconSize: 30,
                                icon: Icon(CustomIcons.lifeinsurance, color: Theme.of(context).colorScheme.primary),
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => InsuranceApplicationForm(
                                          name: widget.name,
                                          mobile: widget.mobile,
                                          insurancetype: 'Life'
                                      )
                                  ));
                                }),
                          ],
                        )
                    ),
                  ),
                ),
                Card(
                  child: Container(
                    width: 112,
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      border: Border (
                        top: BorderSide(width: 3, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    child: Container(
                        alignment: Alignment.center,
                        child: ListView(
                          children: <Widget>[
                            Text('Health Insurance', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                            IconButton(
                                icon: Icon(CustomIcons.medicalinsurance, color: Theme.of(context).colorScheme.primary),
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => InsuranceApplicationForm(
                                          name: widget.name,
                                          mobile: widget.mobile,
                                          insurancetype: 'Health'
                                      )
                                  ));
                                }),
                          ],
                        )
                    ),
                  ),
                ),
              ],
            ),
          ),
          vehicleSegmentsFetched ?
          SizedBox(
            child: Container(
                height: 360,
                child: GridView.count(
                    crossAxisCount: 3,
                    scrollDirection: Axis.vertical,
                    children: List.generate(vehicleSegments.length,(index) {
                      Icon segmentIcon;
                      if(vehicleSegments[index]['NAME'].toString().contains('CONSTRUCTION VEHICLE')) {
                        segmentIcon = Icon(CustomIcons.constructionvehicle, size: 50, color: Theme.of(context).colorScheme.primary);
                      } else if(vehicleSegments[index]['NAME'].toString().contains('FARM EQUIPMENT')) {
                        segmentIcon = Icon(CustomIcons.farmequipment, size: 30, color: Theme.of(context).colorScheme.primary);
                      } else if(vehicleSegments[index]['NAME'].toString().contains('LCV')) {
                        segmentIcon = Icon(CustomIcons.lcv, size: 50, color: Theme.of(context).colorScheme.primary);
                      } else if(vehicleSegments[index]['NAME'].toString().contains('MACHINERY')) {
                        segmentIcon = Icon(CustomIcons.machinery, size: 50, color: Theme.of(context).colorScheme.primary);
                      } else if(vehicleSegments[index]['NAME'].toString().contains('MHCV')) {
                        segmentIcon = Icon(CustomIcons.mhcv, size: 40, color: Theme.of(context).colorScheme.primary);
                      } else if(vehicleSegments[index]['NAME'].toString().contains('PASSENGER 3WHEELER')) {
                        segmentIcon = Icon(CustomIcons.threewheeler, size: 30, color: Theme.of(context).colorScheme.primary);
                      } else if(vehicleSegments[index]['NAME'].toString().contains('PASSENGER COMMERCIAL')) {
                        segmentIcon = Icon(CustomIcons.passengercommercial, size: 40, color: Theme.of(context).colorScheme.primary);
                      } else if(vehicleSegments[index]['NAME'].toString().contains('PRIVATE CAR')) {
                        segmentIcon = Icon(CustomIcons.privatecar, size: 50, color: Theme.of(context).colorScheme.primary);
                      } else if(vehicleSegments[index]['NAME'].toString().contains('TWO WHEELER')) {
                        segmentIcon = Icon(CustomIcons.twowheeler, size: 50, color: Theme.of(context).colorScheme.primary);
                      } else {
                        segmentIcon = Icon(CustomIcons.truck, color: Theme.of(context).colorScheme.primary);
                      }
                      return Container(
                        child: Card(
                          elevation: 3.0,
                          shape: RoundedRectangleBorder(
                              borderRadius : BorderRadius.all(Radius.circular(5)),
                              side: BorderSide(width: 1, color: Theme.of(context).colorScheme.primary)
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              children: [
                                Text(vehicleSegments[index]['NAME'], textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
                                ((vehicleSegments[index]['NAME']).toString().length > 13)? SizedBox() : SizedBox(height: 12),
                                Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.rotationY(pi),
                                  child: IconButton(icon: segmentIcon, onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(
                                        builder: (_) => InsuranceApplicationForm(
                                            name: widget.name,
                                            mobile: widget.mobile,
                                            insurancetype: 'vehicle',
                                            vehiclesegmentindex: index,
                                            vehiclesegment: vehicleSegments[index]['NAME']
                                        )
                                    ));
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    })
                ),
            )
          ) : vehicleInsurancePressed ?
          SizedBox(
              height: 40,
              child: Center(
                  child: Container(
                      child: Text('Loading..')
                  )
              )
          ) : SizedBox()
        ],
      ),
    );
  }
}

class InsuranceApplicationForm extends StatefulWidget {
  InsuranceApplicationForm({Key key, this.name, this.mobile, this.insurancetype, this.vehiclesegmentindex, this.vehiclesegment}) : super(key: key);
  final String name;
  final String mobile;
  final String insurancetype;
  final int vehiclesegmentindex;
  final String vehiclesegment;
  @override
  _InsuranceApplicationFormState createState() => _InsuranceApplicationFormState();
}

class _InsuranceApplicationFormState extends State<InsuranceApplicationForm> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  TextEditingController othersController = TextEditingController(text: '');
  TextEditingController preInsurerController = TextEditingController(text: '');
  String selectedCity = 'Bengaluru';
  String selectedVehicleName = 'Select';
  String selectedManufacturer = 'Select';
  String selectedVehicleModel = 'Select';
  FocusNode myFocusNode;

  @override
  void initState() {
    super.initState();
    myFocusNode = FocusNode();
  }

  @override
  void dispose() {
    myFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var config = AppConfig.of(context);
    return FutureBuilder<String>(
        future: MyApp().getHttpData(config.financeUrl),
        builder: (context, AsyncSnapshot<String> snapshot) {
          Set<String> uniqueManufacturers = Set();
          Set<String> uniqueVehicleNames = Set();
          List<String> manufacturers = <String>['Select','Loading..'];
          List<String> vehiclenames = <String>['Select'];
          List<String> vehiclemodels = <String>['Select','2010','2011','2012','2013','2014','2015','2016','2017','2018','2019','2020'];
          if (snapshot.hasData && widget.insurancetype.contains('vehicle')) {
            Map<String, dynamic> jsonMap = jsonDecode(snapshot.data);
            List<dynamic> vehicleSegmentsDetails = jsonMap['VEHICLE SEGMENTS'][widget.vehiclesegmentindex]['DETAILS'];
            List.generate(vehicleSegmentsDetails.length, (index) {
              uniqueManufacturers.add(vehicleSegmentsDetails[index]['MANUFACTURER']);
              if (selectedManufacturer.contains(vehicleSegmentsDetails[index]['MANUFACTURER'])) {
                uniqueVehicleNames.add(vehicleSegmentsDetails[index]['ASSET DESCRIPTION']);
              }
            });
            manufacturers.removeAt(1);
            manufacturers.addAll(uniqueManufacturers);
            if (!selectedManufacturer.contains('Select')) {
              uniqueVehicleNames.add('Others');
            }
            vehiclenames.addAll(uniqueVehicleNames);
          }
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
                    widget.insurancetype.contains('vehicle') ?
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: <Widget> [
                          Flexible(
                            child: TextFormField(
                              initialValue: widget.vehiclesegment,
                              readOnly: true,
                              decoration: InputDecoration(
                                enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)
                                ),
                                labelText: 'Vehicle Insurance > Vehicle Segment',
                              ),
                            ),
                          ),
                          IconButton(icon: Icon(CustomIcons.vehicleinsurance, color: Theme.of(context).colorScheme.primary), onPressed: null),
                        ],
                      ),
                    ) :
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: <Widget> [
                          Flexible(
                            child: TextFormField(
                              initialValue: widget.insurancetype,
                              readOnly: true,
                              decoration: InputDecoration(
                                enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)
                                ),
                                labelText: 'Insurance',
                              ),
                            ),
                          ),
                          IconButton(icon: Icon(CustomIcons.generalinsurance, size: 30, color: Theme.of(context).colorScheme.primary), onPressed: null),
                        ],
                      ),
                    ),
                    widget.insurancetype.contains('vehicle') ?
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: <Widget> [
                          Flexible(
                            child: AbsorbPointer(
                              absorbing: selectedVehicleName.contains('Select') ? false : true,
                              child: DropdownButtonFormField<String>(
                                value: selectedManufacturer,
                                decoration: InputDecoration(
                                  enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)
                                  ),
                                  labelText: 'Manufacturer Name*',
                                ),
                                onChanged: (String changedManufacturer) {
                                  setState(() {
                                    if(!changedManufacturer.contains('Loading..')) {
                                      selectedManufacturer = changedManufacturer;
                                    }
                                  });
                                },
                                items: manufacturers
                                    .map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                validator: (value) {
                                  if (value.contains('Select')) {
                                    return 'Please select the manufacturer name';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                          IconButton(icon: Icon(CustomIcons.truck, color: Theme.of(context).colorScheme.primary), onPressed: null),
                        ],
                      ),
                    ) : SizedBox(),
                    widget.insurancetype.contains('vehicle') ?
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: <Widget> [
                          Flexible(
                            child: DropdownButtonFormField<String>(
                              value: selectedVehicleName,
                              decoration: InputDecoration(
                                enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)
                                ),
                                labelText: 'Vehicle Name*',
                              ),
                              onChanged: (String changedVehicleName) {
                                setState(() => selectedVehicleName = changedVehicleName);
                              },
                              items: vehiclenames
                                  .map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                    value: value,
                                    child: value.length > 38 ? Text(value, style: TextStyle(fontSize: 6)) : value.length > 32 ? Text(value, style: TextStyle(fontSize: 8)) : value.length > 26 ? Text(value, style: TextStyle(fontSize: 10)) : Text(value, style: TextStyle(fontSize: 12))
                                );
                              }).toList(),
                              validator: (value) {
                                if (value.contains('Select')) {
                                  return 'Please select the vehicle name';
                                }
                                return null;
                              },
                            ),
                          ),
                          IconButton(icon: Icon(CustomIcons.truck, color: Theme.of(context).colorScheme.primary), onPressed: null),
                        ],
                      ),
                    ) : SizedBox(),
                    widget.insurancetype.contains('vehicle') ?
                    selectedVehicleName.contains('Others') ? Container(
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
                                  return 'Please enter the vehicle name';
                                }
                                return null;
                              },
                            ),
                          ),
                          IconButton(icon: Icon(CustomIcons.truck, color: Theme.of(context).colorScheme.primary), onPressed: null),
                        ],
                      ),
                    ) : SizedBox() : SizedBox(),
                    widget.insurancetype.contains('vehicle') ?
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: <Widget> [
                          Flexible(
                            child: DropdownButtonFormField<String>(
                              value: selectedVehicleModel,
                              decoration: InputDecoration(
                                enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)
                                ),
                                labelText: 'Vehicle Model*',
                              ),
                              onChanged: (String changedVehicleModel) {
                                setState(() => selectedVehicleModel = changedVehicleModel);
                              },
                              items: vehiclemodels
                                  .map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value)
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
                    ) : SizedBox(),
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: <Widget> [
                          Flexible(
                            child: TextFormField(
                              controller: preInsurerController,
                              decoration: InputDecoration(
                                enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)
                                ),
                                labelText: 'Previous Insurer Details (if any)',
                              ),
                            ),
                          ),
                          IconButton(icon: Icon(CustomIcons.generalinsurance, size: 30, color: Theme.of(context).colorScheme.primary), onPressed: null),
                        ],
                      ),
                    ),
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
                      child: RaisedButton(
                        onPressed: () async {
                          if (_formKey.currentState.validate()) {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return widget.insurancetype.contains('vehicle') ? ShowPremiumDialog(
                                    name: widget.name,
                                    mobile: widget.mobile,
                                    tab: 0,
                                    insurancetype: widget.insurancetype,
                                    vehiclesegment: widget.vehiclesegment,
                                    manufacturer: selectedManufacturer,
                                    vehiclename: (selectedVehicleName.contains('Others') ? othersController.text : selectedVehicleName),
                                    vehiclemodel: int.parse(selectedVehicleModel),
                                    previousinsurer: preInsurerController.text.isNotEmpty ? preInsurerController.text : '',
                                    city: selectedCity,
                                  ) : ShowPremiumDialog(
                                    name: widget.name,
                                    mobile: widget.mobile,
                                    tab: 0,
                                    insurancetype: widget.insurancetype,
                                    previousinsurer: preInsurerController.text.isNotEmpty ? preInsurerController.text : '',
                                    city: selectedCity,
                                  );
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
    );
  }
}

class DepositTab extends StatefulWidget {
  DepositTab({Key key, this.name, this.mobile}) : super(key: key);
  final String name;
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
                  IconButton(icon: Icon(CustomIcons.deposithand, size: 30, color: Theme.of(context).colorScheme.primary), onPressed: null),
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
                        width: 112,
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          border: Border (
                            top: BorderSide(width: 3, color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                        child: Container(
                            child: Column(
                                children: <Widget>[
                                  Text('Debenture', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                                  IconButton(
                                      iconSize: 30,
                                      icon: Icon(CustomIcons.debenture, color: Theme.of(context).colorScheme.primary),
                                      onPressed: () {
                                        Navigator.push(context, MaterialPageRoute(
                                            builder: (_) => DepositApplicationForm(
                                                name: widget.name,
                                                mobile: widget.mobile,
                                                deposittype: 'Debenture'
                                            )
                                        ));
                                      }),
                                ]
                            )
                        )
                    )
                ),
                Card(
                    child: Container(
                        width: 112,
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          border: Border (
                            top: BorderSide(width: 3, color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                        child: Container(
                            child: Column(
                                children: <Widget>[
                                  Text('Deposit', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                                  IconButton(
                                      iconSize: 35,
                                      icon: Icon(CustomIcons.depositbag, size:40, color: Theme.of(context).colorScheme.primary),
                                      onPressed: () {
                                        Navigator.push(context, MaterialPageRoute(
                                            builder: (_) => DepositApplicationForm(
                                                name: widget.name,
                                                mobile: widget.mobile,
                                                deposittype: 'Deposit'
                                            )
                                        ));
                                      }),
                                ]
                            )
                        )
                    )
                )
              ]
            )
          )
        ],
      ),
    );
  }
}

class DepositApplicationForm extends StatefulWidget {
  DepositApplicationForm({Key key, this.name, this.mobile, this.deposittype}) : super(key: key);
  final String name;
  final String mobile;
  final String deposittype;
  @override
  _DepositApplicationFormState createState() => _DepositApplicationFormState();
}

class _DepositApplicationFormState extends State<DepositApplicationForm> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  TextEditingController amountController = TextEditingController(text: '');
  String selectedCity = 'Bengaluru';
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
                      child: TextFormField(
                        initialValue: widget.deposittype,
                        readOnly: true,
                        decoration: InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)
                          ),
                          labelText: 'Deposit',
                        ),
                      ),
                    ),
                    IconButton(icon: Icon(CustomIcons.deposithand, size:30, color: Theme.of(context).colorScheme.primary), onPressed: null),
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
                          labelText: 'Deposit Amount*',
                        ),
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'Please enter the deposit amount';
                          } else if (!value.contains(RegExp(r'^[0-9]+$'))) {
                            return 'Please enter only the numbers';
                          }
                          return null;
                        },
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
                child: RaisedButton(
                  onPressed: () async {
                    if (_formKey.currentState.validate()) {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return SubmittingDialog();
                          }
                      );
                      String message = ': [DEPOSIT REQUEST] ';
                      message = message + 'Name: ' + widget.name + ', ';
                      message = message + 'Phone #: ' + widget.mobile + ', ';
                      message = message + 'City: ' + selectedCity + ', ';
                      message = message + 'Product: ' + widget.deposittype + ', ';
                      message = message + 'Investment Amount: ' + (amountController.text.isEmpty ? 'none' : amountController.text);
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

class ShowEMIDialog extends StatelessWidget {
  ShowEMIDialog({Key key, this.name, this.mobile, this.tab, this.vehiclesegment, this.manufacturer, this.vehiclename, this.loanamount, this.city}) : super(key: key);
  final String name;
  final String mobile;
  final int tab;
  final String vehiclesegment;
  final String manufacturer;
  final String vehiclename;
  final int loanamount;
  final String city;
  @override
  Widget build(BuildContext context) {
    var config = AppConfig.of(context);
    return FutureBuilder<String>(
      future: MyApp().getHttpData(config.financeUrl),
      builder: (context, AsyncSnapshot<String> snapshot) {
        if (snapshot.hasData) {
          Map<String, dynamic> jsonMap = jsonDecode(snapshot.data);
          var interestRate = (int.parse(cast<String>(jsonMap['SETTINGS']['finance_interest_rate'])))/100;
          var totalAmount = loanamount + (loanamount * interestRate);
          var twoYearEMI = roundDouble(totalAmount/24, 2);
          var threeYearEMI = roundDouble(totalAmount/36, 2);
          var fourYearEMI = roundDouble(totalAmount/48, 2);
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0)
            ),
            child: Container(
              height: 200,
              padding: const EdgeInsets.all(12.0),
              child: Center(
                child: Column(
                  children: [
                    SizedBox(
                        height: 30
                    ),
                    Text('EMI ₹$twoYearEMI for 2 years'),
                    Text('EMI ₹$threeYearEMI for 3 years'),
                    Text('EMI ₹$fourYearEMI for 4 years'),
                    SizedBox(
                        height: 20
                    ),
                    RaisedButton(
                        onPressed: () async {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return SubmittingDialog();
                              }
                          );
                          String message = ': [FINANCE REQUEST] ';
                          message = message + 'Name: ' + name + ', ';
                          message = message + 'Phone #: ' + mobile + ', ';
                          message = message + 'City: ' + city + ', ';
                          message = message + 'Vehicle Segment: ' + vehiclesegment + ', ';
                          message = message + 'Manufacturer Name: ' + manufacturer + ', ';
                          message = message + 'Vehicle Name: ' + vehiclename + ', ';
                          message = message + 'Loan Amount: ' + loanamount.toString();
                          await MyApp().sendWhatsApp(config.twilioBaseUrl, config.twilioAccountSid, config.twilioApikeySid, config.twilioSecret, config.twilioWhatsappNumber, config.recipientNumber, message);
                          Navigator.of(context).pop();
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return SubmitDialog(name: name, mobile: mobile, tab: 0);
                            }
                          );
                        },
                        child: Text('Ok'),
                        color: Theme.of(context).colorScheme.primary
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0)
            ),
            child: Container(
              height: 200,
              padding: const EdgeInsets.all(12.0),
              child: Center(
                child: Column(
                  children: [
                    SizedBox(
                        height: 70
                    ),
                    Text('Calculating EMI..'),
                  ],
                ),
              ),
            ),
          );
        }
      }
    );
  }
}

class ShowPremiumDialog extends StatelessWidget {
  ShowPremiumDialog({Key key, this.name, this.mobile, this.tab, this.insurancetype, this.vehiclesegment, this.manufacturer, this.vehiclename, this.vehiclemodel, this.previousinsurer, this.city}) : super(key: key);
  final String name;
  final String mobile;
  final int tab;
  final String insurancetype;
  final String vehiclesegment;
  final String manufacturer;
  final String vehiclename;
  final int vehiclemodel;
  final String previousinsurer;
  final String city;
  @override
  Widget build(BuildContext context) {
    var config = AppConfig.of(context);
    return FutureBuilder<String>(
        future: MyApp().getHttpData(config.financeUrl),
        builder: (context, AsyncSnapshot<String> snapshot) {
          var premiumamount = '0';
          if (snapshot.hasData) {
            Map<String, dynamic> jsonMap = jsonDecode(snapshot.data);
            List<dynamic> premiumrates = jsonMap['SETTINGS']['premium_rates'];
            if(insurancetype.contains('vehicle')) {
              premiumrates.forEach((premiumrate) {
                if ((premiumrate as Map<String, dynamic>).containsKey('$vehiclemodel')) {
                  premiumamount = premiumrate['$vehiclemodel'];
                }
              });
            } else {
              premiumamount = '4500';
            }
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0)
              ),
              child: Container(
                height: 200,
                padding: const EdgeInsets.all(12.0),
                child: Center(
                  child: Column(
                    children: [
                      SizedBox(
                          height: 30
                      ),
                      Text('Premium amount will be ₹$premiumamount'),
                      SizedBox(
                          height: 20
                      ),
                      RaisedButton(
                          onPressed: () async {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return SubmittingDialog();
                                }
                            );
                            String message = ': [INSURANCE REQUEST] ';
                            message = message + 'Name: ' + name + ', ';
                            message = message + 'Phone #: ' + mobile + ', ';
                            message = message + 'City: ' + city + ', ';
                            message = message + 'Insurance Type: ' + insurancetype + ', ';
                            if(insurancetype.contains('vehicle')) {
                              message = message + 'Vehicle Segment: ' + vehiclesegment + ', ';
                              message = message + 'Manufacturer Name: ' + manufacturer + ', ';
                              message = message + 'Vehicle Name: ' + vehiclename + ', ';
                              message = message + 'Vehicle Model: ' + vehiclemodel.toString() + ', ';
                            }
                            if(previousinsurer.isNotEmpty) {
                              message = message + 'Previous Insurer: ' + previousinsurer + ', ';
                            }
                            message = message + 'Premium Amount: ' + premiumamount;
                            await MyApp().sendWhatsApp(config.twilioBaseUrl, config.twilioAccountSid, config.twilioApikeySid, config.twilioSecret, config.twilioWhatsappNumber, config.recipientNumber, message);
                            Navigator.of(context).pop();
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return SubmitDialog(name: name, mobile: mobile, tab: 1);
                                }
                            );
                          },
                          child: Text('Ok'),
                          color: Theme.of(context).colorScheme.primary
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0)
              ),
              child: Container(
                height: 200,
                padding: const EdgeInsets.all(12.0),
                child: Center(
                  child: Column(
                    children: [
                      SizedBox(
                          height: 70
                      ),
                      Text('Calculating Premium..'),
                    ],
                  ),
                ),
              ),
            );
          }
        }
    );
  }
}

class SubmittingDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0)
      ),
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

T cast<T>(x) => x is T ? x : null;

double roundDouble(double value, int places){
  double mod = pow(10.0, places);
  return ((value * mod).round().toDouble() / mod);
}