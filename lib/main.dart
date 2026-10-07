import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Future<Endereco> buscaEndereco(String cep) async {
  final resposta = await http.get(
    Uri.parse('https://viacep.com.br/ws/$cep/json/'),
    headers: {'Accept': 'application/json'},
  );

  if (resposta.statusCode == 200) {
    final Map<String, dynamic> dados = jsonDecode(resposta.body);
    if (dados.containsKey('erro')) {
      throw Exception('CEP não encontrado.');
    }
    return Endereco.fromJson(dados);
  } else {
    throw Exception('Falha ao carregar endereço.');
  }
}

class Endereco {
  final String rua;
  final String bairro;
  final String cidade;
  final String estado;

  const Endereco({
    required this.rua,
    required this.bairro,
    required this.cidade,
    required this.estado,
  });

  factory Endereco.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'logradouro': String logradouro,
        'bairro': String bairro,
        'localidade': String localidade,
        'uf': String uf
      } =>
        Endereco(
          rua: logradouro,
          bairro: bairro,
          cidade: localidade,
          estado: uf,
        ),
      _ => throw const FormatException('Falha no carregamento...'),
    };
  }
}

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TextEditingController _controller = TextEditingController(text: '01001000');
  late Future<Endereco> enderecoFuturo;

  @override
  void initState() {
    super.initState();
    enderecoFuturo = buscaEndereco(_controller.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Consulta CEP',
      home: Scaffold(
        appBar: AppBar(title: const Text('Consulta CEP')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  decoration: const InputDecoration(labelText: 'CEP'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      enderecoFuturo = buscaEndereco(_controller.text);
                    });
                  },
                  child: const Text('Buscar'),
                ),
                const SizedBox(height: 20),
                FutureBuilder<Endereco>(
                  future: enderecoFuturo,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Column(
                        children: [
                          Text('Rua: ${snapshot.data!.rua}'),
                          Text('Bairro: ${snapshot.data!.bairro}'),
                          Text('Cidade: ${snapshot.data!.cidade}'),
                          Text('Estado: ${snapshot.data!.estado}'),
                        ],
                      );
                    } else if (snapshot.hasError) {
                      return Text('${snapshot.error}');
                    }

                    return const Text('Carregando...');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}