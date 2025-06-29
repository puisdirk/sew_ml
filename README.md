# SewML

SewML is a human-readable language for describing sewing patterns, akin to the instruction lists you can find in tailoring books.

You can use it to create patterns, share them, play around, etc.

### Example

To draw a simple square of 10cm by 10cm, you could use the following instructions:
```
point P_1 10cm east of origin
point P_2 10cm north of P_1
point P_3 10cm north of origin
line L_1 from origin to P_1
line L_2 from P_1 to P_2
line L_3 from P_2 to P_3
line L_4 from P_3 to origin
```
This illustrates how SewML works:

- each line is a command
- you can define the following objects: points, lines, curves, measurements, parts and layouts
- for each object, you specify a label (P_1, L_1, etc) so you can refer to it in subsequent commands

### Differences with tailoring books
__Directions__
\
In classic tailoring books, you would get something like this:

```
0-1 scye depth plus 4cm.
0-2 natural waist length plus 3cm.
0-3 shirt length plus 8cm.
```
And this would be accompanied by a finished drawing. You would constantly refer to the drawing to know which direction these points and lines go in. SewML is not smart enough to do this, so we need to be more specific and provide the directions relative to existing points. E.g.
```
measurement M_scye_depth 18cm
measurement M_natural_waist_length 30cm
measurement M_shirt_length 50cm
point P_1 M_scye_depth + 40 south of origin
point P_2 M_natural_waist_length + 30 south of origin
point P_3 M_shirt_length + 80 south of origin
line L_1 from origin to P_3
```
__Square across__
\
In classic tailoring books, you might find an instruction to "square across", i.e. draw a line perpendicular to another line. 
\
In SewML, all lines need a start point and an end point, so we don't allow a "square across" instruction that would produce an infinite line. But it's pretty easy to translate to SewML parlance using north, east, west, etc.

### UI
SewML currently has a viewer and the language library rolled into one (we'll split them later).

// TODO: picture


### Complete Syntax
 // TODO: language diagrams

### Future developments
//TODO: slash-and-spread, folds, export to freesewing.org code, ...