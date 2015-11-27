program g0;

{ VARIABLE,s }
var
  p0_name       :Array[1..8] of char;
  p0_type       :char; {'w' warrior, 'r' ranger, 'm' mage}
  p0_hp         :byte; { Nece biti vise od ((2^8)-1), zar ne? }
  temp_confirm  :char;

procedure reset;
begin
     p0_name      := 'Tusk';
     p0_type      := 'w';
     p0_hp        := 255;
     temp_confirm := 'n';
end;

{ INTRO FUNCTION }
function write_classname(ttype: char): char;
begin
     if (ttype = 'w') then write('warrior')
     else if (ttype = 'r') then write('ranger')
     else write('mage');
     exit(' ');
end;

procedure intro;
begin
     writeln('Welcome to this amazing game.');
     writeln();

     temp_confirm := ' ';
     while ( not (temp_confirm = 'y') ) do begin
       writeln('Who are you, and what''s your name?');
       write('>>> My name is ');readln(p0_name);
       write('>>> And I am a ([W]arrior, [R]anger, [M]age): ');
       readln(p0_type);
       writeln('So you are ', p0_name, ', a ', write_classname(p0_type), '. Correct? [Y/N]: ');
       readln(temp_confirm);
     end;
end;

{ MAIN HERE }
begin
     reset();
     intro();
     readLn();
end.

