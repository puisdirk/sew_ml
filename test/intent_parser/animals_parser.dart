
import 'package:petitparser/petitparser.dart';
import 'package:sew_ml/parser/intent_parser/lock_on_intent_parser.dart';
import 'package:sew_ml/parser/intent_parser/buffer_predicate.dart';
import 'package:sew_ml/parser/intent_parser/intent_parser.dart';

class AnimalsParser extends GrammarDefinition {
  
  @override
  Parser start() => color() & animal() & consumption();

  Parser color() => red() | brown() | yellow();
  Parser red() => string('red').trim();
  Parser brown() => string('brown').trim();
  Parser yellow() => string('yellow').trim();

  Parser animal() => lockIntent([
    passOne(fox(), bufferStartsWith('red'), message: 'only foxes are red'),
    passAny(fox() | bear(), [bufferStartsWith('red'), bufferStartsWith('brown')], message: 'if it is red or brown, it must be a bear or a fox'),
  ], message: 'bears are brown while foxes can be red or brown');

/*
  Parser animal() => LockOnIntentParser([
    IntentParser(fox(), [BufferStartsWith('red')], message: 'only foxes are red'),
    IntentParser(fox() | bear(), [
      BufferStartsWith('red'), 
      BufferStartsWith('brown')
    ], passAll: false, message: 'if it is red or brown, it must be a bear or a fox'),
  ], message: 'bears are brown while foxes can be red or brown');
*/

  Parser fox() => string('fox').trim();
  Parser bear() => string('bear').trim();

  Parser consumption() => 
    string('eats').trim() & 
    LockOnIntentParser([
      IntentParser(honey() | rabbit(), [BufferContains('bear')], message: 'bears eat rabbits or honey'),
      IntentParser(rabbit(), [BufferContains('fox')], message: 'foxes only eat rabbits'),
    ], message: 'bears and foxes eat rabbits, but only bears eat honey');
  Parser honey() => string('honey').trim();
  Parser rabbit() => string('rabbit').trim();
}