
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
    passOne(bufferStartsWith('red'), fox(), message: 'only foxes are red'),
    passAny([bufferStartsWith('red'), bufferStartsWith('brown')], fox() | bear(), message: 'if it is red or brown, it must be a bear or a fox'),
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

/*  Parser consumption() => 
    string('eats').trim() & 
    LockOnIntentParser([
      IntentParser([BufferContains('bear')], honey() | rabbit(), message: 'bears eat rabbits or honey'),
      IntentParser([BufferContains('fox')], rabbit(), message: 'foxes only eat rabbits'),
    ], message: 'bears and foxes eat rabbits, but only bears eat honey');
*/
  Parser consumption() =>
    string('eats').trim() &
    lockIntent([
      passOne(bufferContains('bear'), honey() | rabbit(), message: 'bears eat rabbits or honey'),
      passOne(bufferContains('fox'), rabbit(), message: 'foxes only eat rabbits'),
    ], message: 'bears and foxes eat rabbits, but only bears eat honey');
  Parser honey() => string('honey').trim();
  Parser rabbit() => string('rabbit').trim();
}