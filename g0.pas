program game0;

{ VARIABLE,s }
const
     buffer_size  = 16;
     buffer_sized = 128; { za dialog }
type
    c_string  = Array [1..buffer_size] of char;
    c_stringd = Array [1..buffer_sized] of char; { za dialog }
    { Enumeracije }
    DMG_TYPE = (DMG_PUNCH, DMG_CUT, DMG_PIERCE);
    E_ENEMY = (ENEMY_NULL, ENEMY_WOLF0, ENEMY_WOLF1);
var
  p0_name         :c_string;
  p0_type         :char; {'w' warrior, 'r' ranger, 'm' mage}
  p0_hp, p0_hpmax :integer;
  p0_atr_str      :byte;
  p0_atr_agl      :byte;
  p0_atr_int      :byte;
  p0_lvl          :byte;
  p0_exp          :integer;
  p0_expgoal      :integer;
  p0_atr_ar       :byte;
  p0_dmgtype      :DMG_TYPE;
  p0_weak         :DMG_TYPE;
  temp_confirm    :char;

{ Pocetne vrednosti, za svaki slucaj! }
procedure reset;
begin
     p0_name      := 'Tuskarr ';
     p0_type      := 'w';
     p0_hp        := 15;
     p0_hpmax     := 25;
     p0_atr_str   := 0;
     p0_atr_agl   := 0;
     p0_atr_int   := 0;
     p0_atr_ar    := 0;
     p0_lvl       := 0;
     p0_exp       := 0;
     p0_expgoal   := 20;
     p0_dmgtype   := DMG_PIERCE;
     p0_weak      := DMG_PIERCE;
     temp_confirm := 'n';
end;

{ Da li je znak jednak nekim drugim znakom, sluzi zbog velikog/malog slova }
{ UVEK KORISTITI MALO SLOVO ZA c1! }
function chrcmp(c0,c1:char): boolean;
begin
     { 'ord' kastuje char u byte, barem u ovom slucaju }
     if( (c0 = c1) or (ord(c0) = ord(c1)-32) ) then exit(true);
     exit(false);
end;

{ Pise string(niz znakova), preskace razmak. }
procedure write_trimstring(name: c_string ) ;
var
   index: byte;
begin
     index := 0;
     while (index < buffer_size) do begin
           if ( not(name[index] = ' ') ) then begin
              write(name[index]);
           end;
           index := index + 1;
     end;
end;

{ Pise ime klase u zavisnosti sta je igrac odabrao }
procedure write_classname(ttype: char);
begin
     if (ttype = 'w') then write('warrior')
     else if (ttype = 'r') then write('ranger')
     else write('mage');
end;

{ LEVEL UP! }
procedure p0_lvlup(); 
var
   bonus_atr: byte;
   bonus_chr: char;
begin
     { Pocetne vrednosti, ignorisati, navika }
     bonus_atr := 4;
     bonus_chr := 's';

     { Dodaj nivo }
     p0_lvl := p0_lvl + 1;
     writeln(' [LVL UP]');
     write(p0_name);
     writeln(' has gained a level! Currently standing at lvl. ', p0_lvl);

     { Dodaj atribute }
     writeln('STARTING ATTRIBUTES: ');
     writeln('STR: ', p0_atr_str);
     writeln('AGL: ', p0_atr_agl);
     writeln('INT: ', p0_atr_int);
     writeln('Bonus points: ', bonus_atr);
     while (bonus_atr > 0) do begin
           write('Add a point to an atribute [S]trength, [A]gility, [I]nteligence, (', bonus_atr, ') remain: ');
           readln(bonus_chr);
           if(chrcmp(bonus_chr, 's')) then begin p0_atr_str := p0_atr_str + 1; bonus_atr := bonus_atr - 1; end
           else if(chrcmp(bonus_chr, 'a')) then begin p0_atr_agl := p0_atr_agl + 1; bonus_atr := bonus_atr - 1; end
           else if(chrcmp(bonus_chr, 'i')) then begin p0_atr_int := p0_atr_int + 1; bonus_atr := bonus_atr - 1; end;
     end;
     writeln();
     writeln('RESULTING ATTRIBUTES: ');
     writeln('STR: ', p0_atr_str);
     writeln('AGL: ', p0_atr_agl);
     writeln('INT: ', p0_atr_int);
end;

procedure p0_gainexp(plusexp: integer);
var
   i, j: integer;
begin               
     i := (p0_exp*10) div p0_expgoal;
     j := 0;
     write('EXP: ');
     while(j<i) do begin
          write('>');
          j := j + 1;
     end;

     p0_exp := p0_exp + plusexp;

     i := ((p0_exp*10) div p0_expgoal) - i;
     j := 0;
     while(j<i) do begin
          write('#'); 
          j := j + 1;
     end;

     i := 10 - i;
     j := 0;
     while(j<i) do begin
          write('-');
          j := j + 1;
     end;

     if(p0_exp >= p0_expgoal) then begin
          p0_exp := p0_expgoal - p0_exp;
          p0_lvlup();
     end;
     readln();
end;

{ DIALOG }
procedure dialog(actor: c_string; msg: c_stringd);
begin
     write('<', actor, '> ', msg, ' [V]');
     readln();
end;
procedure dialognoend(actor: c_string; msg: c_stringd);
begin
     write('<', actor, '> ', msg);
end;

{ BATTLE, ignorisanje: ALLY_NULL & ENEMY_NULL }
function calc_dmg(attacker_str, attacker_agl, enemy_str, enemy_agl, enemy_ar:byte; attacker_dtype, enemy_weak:DMG_TYPE): byte;
var dmg: byte;
begin
     dmg := 0;
     if(random(attacker_agl) < random(enemy_agl)) then begin dmg := 0; write('Miss!'); end
     else begin
         dmg := (attacker_str div 2 + random(attacker_str div 2));
         if((dmg - 1) > 0) then dmg := dmg - enemy_ar;
         if(attacker_dtype = enemy_weak) then begin dmg := dmg + enemy_str; write('+Very effective! '); end;
     end;
     exit(dmg);
end;

procedure battle_start(en0,en1,en2: E_ENEMY; en0lvl, en1lvl, en2lvl: byte);
const
   battle_line = 100; { cekanje po potezu }
var
   en0hp, en1hp, en2hp: integer;
   en0_str, en0_agl, en0_int, en0_ar, en0exp  : byte;
   en1_str, en1_agl, en1_int, en1_ar, en1exp  : byte;
   en2_str, en2_agl, en2_int, en2_ar, en2exp : byte;
   en0_dtype, en1_dtype, en2_dtype : DMG_TYPE;
   en0_weak, en1_weak, en2_weak : DMG_TYPE;
   en0name, en1name, en2name : c_string;
   battling: boolean;
   battle_linep0, battle_lineen0, battle_lineen1, battle_lineen2: integer;
   player_choice : char;
   choiceattack : byte;
   dmg, dmgbonus : byte; { Koliko je tezak udarac }
   confirm : boolean; { Potvrdjivanje }
   attacktext : byte;
begin
     en0name := '                ';
     en1name := 'DEAD            ';
     en2name := 'DEAD            ';
     en0name := 'Silver Wolf     ';

     en0hp := 0;
     en0_str := 0;
     en0_agl := 0;
     en0_int := 0; 
     en0_ar  := 1;
     en0exp  := 2;
     en0_weak := DMG_PIERCE;
     en0_dtype := DMG_PUNCH;

     en1hp := 0;
     en1_str := 0;
     en1_agl := 0;
     en1_int := 0;
     en1_ar  := 1; 
     en1exp  := 2;
     en1_weak := DMG_PIERCE;
     en1_dtype := DMG_PUNCH;

     en2hp := 0;
     en2_str := 0;
     en2_agl := 0;
     en2_int := 0;  
     en2_ar  := 1; 
     en2exp  := 0;
     en2_weak := DMG_PIERCE;
     en2_dtype := DMG_PUNCH;

     if(en0 = ENEMY_WOLF0) then begin
          en0name := 'Wolf            ';
          en0hp := 4*en0lvl;
          en0_str := 3*en0lvl;
          en0_agl := 1*en0lvl;
          en0_int := 1*en0lvl;
          en0_ar  := 0;
          en0exp  := 2*en0lvl;
     end
     else if(en0 = ENEMY_WOLF1) then begin
          en0name := 'Silver Wolf     ';
          en0hp := 6*en0lvl;
          en0_str := 4*en0lvl;
          en0_agl := 1*en0lvl;
          en0_int := 1*en0lvl;  
          en0_ar  := 0;   
          en0exp  := 3*en0lvl;
     end;
     
     if(en1 = ENEMY_WOLF0) then begin 
          en1name := 'Wolf            ';
          en1hp := 4*en1lvl;
          en1_str := 3*en1lvl;
          en1_agl := 1*en1lvl;
          en1_int := 1*en1lvl; 
          en1_ar  := 0;     
          en1exp  := 2*en0lvl;
     end
     else if(en1 = ENEMY_WOLF1) then begin 
          en1name := 'Silver Wolf     ';
          en1hp := 6*en1lvl;
          en1_str := 3*en1lvl;
          en1_agl := 1*en1lvl;
          en1_int := 1*en1lvl; 
          en1_ar  := 0;  
          en1exp  := 3*en0lvl;
     end;

     
     if(en2 = ENEMY_WOLF0) then begin  
          en2name := 'Wolf            ';
          en2hp := 4*en2lvl;
          en2_str := 3*en2lvl;
          en2_agl := 1*en2lvl;
          en2_int := 1*en2lvl;  
          en2_ar  := 0;  
          en2exp  := 2*en0lvl;
     end
     else if(en0 = ENEMY_WOLF1) then begin 
          en2name := 'Silver Wolf     ';
          en2hp := 6*en2lvl;
          en2_str := 4*en2lvl;
          en2_agl := 1*en2lvl;
          en2_int := 1*en2lvl; 
          en2_ar  := 0;  
          en2exp  := 3*en0lvl;
     end;

     writeln();
     writeln('INITIALIZE BATTLE!');

     battling := true;
     battle_linep0 := 0;
     battle_lineen0 := 0;
     battle_lineen1 := 0;
     battle_lineen2 := 0;
     dmg := 0;
     while(battling) do begin
          battle_linep0 := battle_linep0 + p0_atr_agl;
          if(battle_linep0 >= 100) then begin
               battle_linep0 := battle_linep0 - 100;
               confirm := false;
               while (not confirm) do begin
                    writeln('Player HP: ', p0_hp, '/', p0_hpmax);
                    writeln('Enemy Name/         HP/ str/ agl/ int');
                    writeln(en0name,'(0)/ ', en0hp, '/   ', en0_str, '/   ', en0_agl, '/   ', en0_int);
                    writeln(en1name,'(1)/ ', en1hp, '/   ', en1_str, '/   ', en1_agl, '/   ', en1_int);
                    writeln(en2name,'(2)/ ', en2hp, '/   ', en2_str, '/   ', en2_agl, '/   ', en2_int);
                    write('> Player''s turn! [A]ttack ');
                    readln(player_choice);
                    if(chrcmp(player_choice, 'a')) then begin
                         write('> Attack index: ');
                         readln(choiceattack);
                         writeln();
                         randomize;
                         if(choiceattack = 0) then begin
                               if(en0hp <= 0) then begin writeln('What do you think you are hitting?'); end;
                               confirm := true;
                               dmg := calc_dmg(p0_atr_str, p0_atr_agl, en0_str, en0_agl, en0_ar, p0_dmgtype, en0_weak);
                               write('Player dealt -', dmg, ' dmg! to '); write_trimstring(en0name); write('! [', en0hp, '->');
                               en0hp := en0hp - dmg;
                               writeln(en0hp, ']');
                               if(en0hp <= 0) then begin
                                     if(p0_dmgtype = DMG_PUNCH) then begin write_trimstring(en0name); writeln(' was beaten to death.') end
                                     else if(p0_dmgtype = DMG_CUT) then begin write_trimstring(en0name); writeln(' got cut.') end
                                     else if(p0_dmgtype = DMG_PIERCE) then begin write_trimstring(en0name); writeln(' was pierced.') end;
                               end;
                         end
                         else if(choiceattack = 1) then begin   
                               if(en1hp <= 0) then begin writeln('What do you think you are hitting?'); end;
                               confirm := true;
                               dmg := calc_dmg(p0_atr_str, p0_atr_agl, en1_str, en1_agl, en0_ar, p0_dmgtype, en1_weak);
                               write('Player dealt -', dmg, ' dmg! to '); write_trimstring(en1name); write('! [', en1hp, '->');
                               en1hp := en1hp - dmg;
                               writeln(en1hp, ']');
                               if(en1hp <= 0) then begin
                                     if(p0_dmgtype = DMG_PUNCH) then begin write_trimstring(en1name); writeln(' was beaten to death.') end
                                     else if(p0_dmgtype = DMG_CUT) then begin write_trimstring(en1name); writeln(' got cut.') end
                                     else if(p0_dmgtype = DMG_PIERCE) then begin write_trimstring(en1name); writeln(' was pierced.') end;
                               end;
                         end
                         else if(choiceattack = 2) then begin 
                               if(en2hp <= 0) then begin writeln('What do you think you are hitting?'); end;
                               confirm := true;
                               dmg := calc_dmg(p0_atr_str, p0_atr_agl, en2_str, en2_agl, en0_ar, p0_dmgtype, en2_weak);
                               write('Player dealt -', dmg, ' dmg! to '); write_trimstring(en2name); write('! [', en2hp, '->');
                               en2hp := en2hp - dmg;
                               writeln(en2hp, ']');
                               if(en2hp <= 0) then begin
                                     if(p0_dmgtype = DMG_PUNCH) then begin write_trimstring(en2name); writeln(' was beaten to death.') end
                                     else if(p0_dmgtype = DMG_CUT) then begin write_trimstring(en2name); writeln(' got cut.') end
                                     else if(p0_dmgtype = DMG_PIERCE) then begin write_trimstring(en2name); writeln(' was pierced.') end;
                               end;
                         end;
                    end;
               end;
          end;

          { ENEMY 0 }
          battle_lineen0 := battle_lineen0 + en0_agl;
          if((battle_lineen0 >= 100) and (en0hp > 0) ) then begin
               write_trimstring(en0name); write(' attacks! ');
               battle_lineen0 := battle_lineen0 - 100;
               dmg := calc_dmg(en0_str, en0_agl, p0_atr_str, p0_atr_agl, p0_atr_ar, en0_dtype, p0_weak);
               write(' Player received -', dmg, ' dmg! [', p0_hp, '->');
               p0_hp := p0_hp - dmg;
               writeln(p0_hp, ']');
               if(p0_hp <= 0) then begin
                    if(en0_dtype = DMG_PUNCH) then writeln('Player was beaten to death.')
                    else if(en0_dtype = DMG_CUT) then writeln('Player got cut.')
                    else if(en0_dtype = DMG_PIERCE) then writeln('Player was pierced.');
                    battling := false;
               end;
          end;
                     
          battle_lineen1 := battle_lineen1 + en1_agl;
          if((p0_hp > 0) and (en1hp > 0) and (battle_lineen1 >= 100)) then begin
               { ENEMY 1 }
               write_trimstring(en1name); write(' attacks! ');
               battle_lineen1 := battle_lineen1 - 100;
               dmg := calc_dmg(en1_str, en1_agl, p0_atr_str, p0_atr_agl, p0_atr_ar, en1_dtype, p0_weak);
               write(' Player received -', dmg, ' dmg! [', p0_hp, '->');
               p0_hp := p0_hp - dmg;
               writeln(p0_hp, ']');
               if(p0_hp <= 0) then begin
                    if(en1_dtype = DMG_PUNCH) then writeln('Player was beaten to death.')
                    else if(en1_dtype = DMG_CUT) then writeln('Player got cut.')
                    else if(en1_dtype = DMG_PIERCE) then writeln('Player was pierced.');
                    battling := false;
               end;
          end;
                                
          battle_lineen2 := battle_lineen2 + en2_agl;
          if((p0_hp > 0) and (en2hp > 0) and (battle_lineen1 >= 100)) then begin
              { ENEMY 2 }
               write_trimstring(en2name); write(' attacks! ');
               battle_lineen2 := battle_lineen2 - 100;
               dmg := calc_dmg(en2_str, en2_agl, p0_atr_str, p0_atr_agl, p0_atr_ar, en2_dtype, p0_weak);
               write(' Player received -', dmg, ' dmg! [', p0_hp, '->');
               p0_hp := p0_hp - dmg;
               writeln(p0_hp, ']');
               if(p0_hp <= 0) then begin
                    if(en2_dtype = DMG_PUNCH) then writeln('Player was beaten to death.')
                    else if(en2_dtype = DMG_CUT) then writeln('Player got cut.')
                    else if(en2_dtype = DMG_PIERCE) then writeln('Player was pierced.');
                    battling := false;
               end;
          end;

          if( (en0hp <= 0) and (en1hp <= 0) and (en2hp <= 0) ) then begin
                battling := false;
                writeln('Victory!');
                writeln('Player has earned ', (en0exp + en1exp + en2exp), ' exp!');
                p0_gainexp(en0exp + en1exp + en2exp+14);
          end;
     end;

end;

{ Prolog }
procedure intro;
var
   decide : char;
   decide_loop : boolean;
begin
     temp_confirm := 'n';
     dialog('*', 'Deep into the forest, you find yourself lost and confused.');
     dialog('*', '"What happend?", you ask yourself while trying to stand up.');
     dialog('*', 'After a long pain, you manage to stand up.');
     dialog('*', 'You immediately hear a sound coming from east.');
     dialog('*', '"It seems like someone''s running", you say to yourself.');

     { Grananje 1. }
     decide_loop := true;
     while( decide_loop ) do begin
            decide_loop := false;
            writeln();
            dialognoend('YOU', 'a) "I should definitely get out here."'); 
            writeln();
            writeln('b) You are courious and want to know who''s coming.');
            writeln('Chose [a] or [b]: ');
            readln(decide);
            if(chrcmp(decide, 'a')) then begin
                 dialog('*', 'You start to run away...');
                 dialog('*', 'The howling can be heard in the distance.');
                 dialog('*', 'The next moment you see a wolf in front of you.');
                 dialog('*', 'You grabbed a jagged stick and prepare for the fray.');
            end
            else if(chrcmp(decide, 'b')) then begin
                 dialog('???', 'What are you doing here?');
                 dialog('???', 'We''ve got to move fast! GO!');
                 dialog('*', 'Without any hesitation, you follow the man.');
                 dialog('*', 'The howling can be heard in the distance.');
                 dialog('*', 'You can guess that they know where you are.');
                 dialog('*', '"Keep running", the man said, like you wanted to stop.');
                 dialog('???', '!!!');
                 dialog('???', 'We are surrounded! Quickly, we''ve got to fight!');
                 dialog('???', 'Grab anything you can, and use it as a weapon!');
                 dialog('*', 'You grabbed a jagged stick and prepare for the fray.');
            end
            else decide_loop := true;
     end;

     { POCETNI ATRIBUTI }
     p0_atr_str   := 2;
     p0_atr_agl   := 2;
     p0_atr_int   := 2;
     p0_atr_ar    := 1;
     p0_hp := 10;
     p0_hpmax := 20;

     battle_start(ENEMY_WOLF0, ENEMY_WOLF1, ENEMY_NULL, 1, 1, 1);
     if(p0_hp <= 0) then begin
         writeln('Game over');
         readln(); readln(); readln();
     end;

     dialog('YOU', 'Hhu...'); 
     battle_start(ENEMY_WOLF0, ENEMY_WOLF1, ENEMY_NULL, 1, 1, 1);
end;

{ MAIN HERE }
begin          
     writeln('Welcome to this amazing game.');
     writeln('');
     randomize;
     reset();
     writeln('CHAPTER 0: PROLUGE');
     intro();
     readLn();
end.
