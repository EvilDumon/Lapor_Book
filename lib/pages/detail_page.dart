import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:laporbook/models/akun.dart';
import 'package:laporbook/models/laporan.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:laporbook/components/styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laporbook/components/status_dialog.dart';

class DetailPage extends StatefulWidget {
  const DetailPage({super.key});
  @override
  State<StatefulWidget> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final _firestore = FirebaseFirestore.instance;
  String? status;
  List<Liked>? listLiked = [];
  final bool _isLoading = false;

  Future launch(String uri) async {
    if (uri == '') return;
    if (!await launchUrl(Uri.parse(uri))) {
      throw Exception('Tidak dapat memanggil : $uri');
    }
  }

  void statusDialog(Laporan laporan) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatusDialog(
          laporan: laporan,
        );
      },
    );
  }

  void getLike(Laporan laporan) async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
          .collection('laporan')
          .where('docId', isEqualTo: laporan.docId)
          .get();

      setState(() {
        listLiked?.clear();
        for (var documents in querySnapshot.docs) {
          List<dynamic>? likeData = documents.data()['liked'];

          likeData?.map((map) {
            return listLiked?.add(Liked(
              uid: map['uid'],
              tanggalLike: map['tanggalLike'],
            ));
          }).toList();
        }
      });
    } catch (e) {
      print(e);
    }
  }

  void like(Akun akun, Laporan laporan) async {
    CollectionReference laporanCollection = _firestore.collection('laporan');
    Timestamp timestamp = Timestamp.fromDate(DateTime.now());
    try {
      listLiked?.add(Liked(
        uid: akun.uid,
        tanggalLike: timestamp.toString(),
      ));
      await laporanCollection.doc(laporan.docId).update({
        'liked': listLiked,
      });
    } catch (e) {
      print(e);
    }
  }

  Future<bool?> isLike(Akun akun, Laporan laporan) async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
          .collection('laporan')
          .where('docId', isEqualTo: laporan.docId)
          .get();

      for (var documents in querySnapshot.docs) {
        List<dynamic>? likeData = documents.data()['liked'];
        likeData?.map((map) {
          if (map['uid'] == akun.uid) return true;
        });
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final arguments =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    Laporan laporan = arguments['laporan'];
    Akun akun = arguments['akun'];

    getLike(laporan);
    Future<bool?> liked = isLike(akun, laporan);

    return Scaffold(
      floatingActionButton: liked == false
          ? FloatingActionButton(
              backgroundColor: primaryColor,
              child: IconButton(
                onPressed: () {
                  like(akun, laporan);
                },
                icon: Image.asset('assets/love.png'),
                iconSize: 35,
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/add', arguments: {
                  'akun': akun,
                });
              },
            )
          : null,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title:
            Text('Detail Laporan', style: headerStyle(level: 3, dark: false)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : SingleChildScrollView(
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        laporan.judul,
                        style: headerStyle(level: 3),
                      ),
                      const SizedBox(height: 15),
                      laporan.gambar != ''
                          ? Image.network(laporan.gambar!)
                          : Image.asset('assets/istock-default.jpg'),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          laporan.status == 'Posted'
                              ? textStatus(
                                  'Posted', Colors.yellow, Colors.black)
                              : laporan.status == 'Process'
                                  ? textStatus(
                                      'Process', Colors.green, Colors.white)
                                  : textStatus(
                                      'Done', Colors.blue, Colors.white),
                          textStatus(
                              laporan.instansi, Colors.white, Colors.black),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: const Center(child: Text('Nama Pelapor')),
                        subtitle: Center(
                          child: Text(laporan.nama),
                        ),
                        trailing: const SizedBox(width: 45),
                      ),
                      ListTile(
                        leading: const Icon(Icons.date_range),
                        title: const Center(child: Text('Tanggal Laporan')),
                        subtitle: Center(
                            child: Text(DateFormat('dd MMMM yyyy')
                                .format(laporan.tanggal))),
                        trailing: IconButton(
                          icon: const Icon(Icons.location_on),
                          onPressed: () {
                            launch(laporan.maps);
                          },
                        ),
                      ),
                      const SizedBox(height: 50),
                      Text(
                        'Deskripsi Laporan',
                        style: headerStyle(level: 3),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(laporan.deskripsi ?? ''),
                      ),
                      if (akun.role == 'admin')
                        Container(
                          width: 250,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                status = laporan.status;
                              });
                              statusDialog(laporan);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Ubah Status'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Container textStatus(String text, var bgcolor, var textcolor) {
    return Container(
      width: 150,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: bgcolor,
          border: Border.all(width: 1, color: primaryColor),
          borderRadius: BorderRadius.circular(25)),
      child: Text(
        text,
        style: TextStyle(color: textcolor),
      ),
    );
  }
}
