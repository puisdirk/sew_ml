
import 'package:flutter_test/flutter_test.dart';
import 'package:petitparser/petitparser.dart';

import 'animals_parser.dart';

void main() {

  group('success', () {
    test('brown bear eats honey', () {
      AnimalsParser pdef = AnimalsParser();
      Parser p = pdef.buildFrom(pdef.start()).end();
      final Result res = p.parse('brown bear eats honey');
      expect(res is Success, true);
    });


    test('brown bear eats rabbit', () {
      AnimalsParser pdef = AnimalsParser();
      Parser p = pdef.buildFrom(pdef.start()).end();
      final Result res = p.parse('brown bear eats rabbit');
      expect(res is Success, true);
    });

    test('brown fox eats rabbit', () {
      AnimalsParser pdef = AnimalsParser();
      Parser p = pdef.buildFrom(pdef.start()).end();
      final Result res = p.parse('brown fox eats rabbit');
      expect(res is Success, true);
    });

    test('red fox eats rabbit', () {
      AnimalsParser pdef = AnimalsParser();
      Parser p = pdef.buildFrom(pdef.start()).end();
      final Result res = p.parse('red fox eats rabbit');
      expect(res is Success, true);
    });
  });

  group('failure', (){
    test('only foxes are red', () {
      AnimalsParser pdef = AnimalsParser();
      Parser p = pdef.buildFrom(pdef.start()).end();
      final Result res = p.parse('red bear eats rabbit');
      expect(res is Failure, true);
      expect(res.message, 'only foxes are red');
    });

    test('foxes only eat rabbits', () {
      AnimalsParser pdef = AnimalsParser();
      Parser p = pdef.buildFrom(pdef.start()).end();
      final Result res = p.parse('red fox eats honey');
      expect(res is Failure, true);
      expect(res.message, 'foxes only eat rabbits');
    });
    
    test('yellow bear', () {
      AnimalsParser pdef = AnimalsParser();
      Parser p = pdef.buildFrom(pdef.start()).end();
      final Result res = p.parse('yellow bear eats rabbit');
      expect(res is Failure, true);
      expect(res.message, 'bears are brown while foxes can be red or brown');
    });
  });
}