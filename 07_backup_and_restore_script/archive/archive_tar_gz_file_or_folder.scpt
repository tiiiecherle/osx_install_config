FasdUAS 1.101.10   ��   ��    k             l    
 ����  O     
  	  I   	������
�� .miscactvnull��� ��� null��  ��   	 m     ��
�� misccura��  ��     
  
 l     ��������  ��  ��        l     ��  ��    , &display dialog "starting archiving..."     �   L d i s p l a y   d i a l o g   " s t a r t i n g   a r c h i v i n g . . . "      l     ��������  ��  ��        l    ����  r        J           m       �    f i l e   ��  m       �    d i r e c t o r y��    o      ����  0 thechoiceslist theChoicesList��  ��       !   l    "���� " r     # $ # I   �� % &
�� .gtqpchltns    @   @ ns   % o    ����  0 thechoiceslist theChoicesList & �� ' (
�� 
prmp ' m     ) ) � * * h S e l e c t   i f   y o u   w a n t   t o   a r c h i v e   a   f i l e   o r   a   d i r e c t o r y : ( �� +��
�� 
inSL + J     , ,  -�� - m     . . � / /  f i l e��  ��   $ o      ���� 0 	inputtype 	inputType��  ��   !  0 1 0 l     �� 2 3��   2  display dialog inputType    3 � 4 4 0 d i s p l a y   d i a l o g   i n p u t T y p e 1  5 6 5 l     �� 7 8��   7 = 7if inputType is not equal to "file" or "directory" then    8 � 9 9 n i f   i n p u t T y p e   i s   n o t   e q u a l   t o   " f i l e "   o r   " d i r e c t o r y "   t h e n 6  : ; : l     �� < =��   < B <	display dialog "Error: No valid input selected, exiting..."    = � > > x 	 d i s p l a y   d i a l o g   " E r r o r :   N o   v a l i d   i n p u t   s e l e c t e d ,   e x i t i n g . . . " ;  ? @ ? l     �� A B��   A  	return    B � C C  	 r e t u r n @  D E D l     �� F G��   F  end if    G � H H  e n d   i f E  I J I l     ��������  ��  ��   J  K L K l    f M���� M Z     f N O P Q N =    % R S R o     !���� 0 	inputtype 	inputType S J   ! $ T T  U�� U m   ! " V V � W W  f i l e��   O k   ( 9 X X  Y Z Y l  ( (�� [ \��   [ � �set inputFolder to (choose file with prompt "Select a file to be archived" default location path to desktop with multiple selections allowed)    \ � ] ] s e t   i n p u t F o l d e r   t o   ( c h o o s e   f i l e   w i t h   p r o m p t   " S e l e c t   a   f i l e   t o   b e   a r c h i v e d "   d e f a u l t   l o c a t i o n   p a t h   t o   d e s k t o p   w i t h   m u l t i p l e   s e l e c t i o n s   a l l o w e d ) Z  ^�� ^ r   ( 9 _ ` _ l  ( 5 a���� a I  ( 5���� b
�� .sysostdfalis    ��� null��   b �� c d
�� 
prmp c m   * + e e � f f 8 S e l e c t   a   f i l e   t o   b e   a r c h i v e d d �� g��
�� 
dflc g I  , 1�� h��
�� .earsffdralis        afdr h m   , -��
�� afdrdesk��  ��  ��  ��   ` o      ���� 0 	inputitem 	inputItem��   P  i j i =  < C k l k o   < =���� 0 	inputtype 	inputType l J   = B m m  n�� n m   = @ o o � p p  d i r e c t o r y��   j  q�� q k   F Y r r  s t s l  F F�� u v��   u � �set inputItem to (choose folder with prompt "Select a directory to be archived" default location path to desktop with multiple selections allowed)    v � w w$ s e t   i n p u t I t e m   t o   ( c h o o s e   f o l d e r   w i t h   p r o m p t   " S e l e c t   a   d i r e c t o r y   t o   b e   a r c h i v e d "   d e f a u l t   l o c a t i o n   p a t h   t o   d e s k t o p   w i t h   m u l t i p l e   s e l e c t i o n s   a l l o w e d ) t  x�� x r   F Y y z y l  F U {���� { I  F U���� |
�� .sysostflalis    ��� null��   | �� } ~
�� 
prmp } m   H K   � � � B S e l e c t   a   d i r e c t o r y   t o   b e   a r c h i v e d ~ �� ���
�� 
dflc � I  L Q�� ���
�� .earsffdralis        afdr � m   L M��
�� afdrdesk��  ��  ��  ��   z o      ���� 0 	inputitem 	inputItem��  ��   Q k   \ f � �  � � � I  \ c�� ���
�� .sysodlogaskr        TEXT � m   \ _ � � � � � T E r r o r :   N o   v a l i d   i n p u t   s e l e c t e d ,   e x i t i n g . . .��   �  ��� � L   d f����  ��  ��  ��   L  � � � l     ��������  ��  ��   �  � � � l  g y ����� � O  g y � � � r   m x � � � n   m t � � � 1   p t��
�� 
posx � o   m p���� 0 	inputitem 	inputItem � o      ����  0 posixinputitem posixinputItem � m   g j � ��                                                                                  sevs  alis    \  macintosh_hd                   BD ����System Events.app                                              ����            ����  
 cu             CoreServices  0/:System:Library:CoreServices:System Events.app/  $  S y s t e m   E v e n t s . a p p    m a c i n t o s h _ h d  -System/Library/CoreServices/System Events.app   / ��  ��  ��   �  � � � l  z � ����� � r   z � � � � n   z � � � � 1   } ���
�� 
strq � o   z }����  0 posixinputitem posixinputItem � o      ���� 0 ipp  ��  ��   �  � � � l     �� � ���   �  display dialog ipp    � � � � $ d i s p l a y   d i a l o g   i p p �  � � � l     ��������  ��  ��   �  � � � l  � � ����� � r   � � � � � l  � � ����� � I  � ��� ���
�� .sysoexecTEXT���     TEXT � b   � � � � � b   � � � � � m   � � � � � � � " e c h o   " $ ( b a s e n a m e   � o   � ����� 0 ipp   � m   � � � � � � � .   |   c u t   - d .   - f 1 ) " . t a r . g z��  ��  ��   � o      ���� "0 defaultsavename defaultSaveName��  ��   �  � � � l     �� � ���   � $ display dialog defaultSaveName    � � � � < d i s p l a y   d i a l o g   d e f a u l t S a v e N a m e �  � � � l  � � ����� � r   � � � � � l  � � ����� � I  � ��� ���
�� .sysoexecTEXT���     TEXT � b   � � � � � b   � � � � � m   � � � � � � �   e c h o   " $ ( d i r n a m e   � o   � ����� 0 ipp   � m   � � � � � � �  ) "��  ��  ��   � o      ���� "0 defaultsavepath defaultSavePath��  ��   �  � � � l     �� � ���   � $ display dialog defaultSavePath    � � � � < d i s p l a y   d i a l o g   d e f a u l t S a v e P a t h �  � � � l  � � ����� � r   � � � � � 4   � ��� �
�� 
psxf � o   � ����� "0 defaultsavepath defaultSavePath � o      ���� 80 defaultsavepathapplescript defaultSavePathApplescript��  ��   �  � � � l     �� � ���   � / )display dialog defaultSavePathApplescript    � � � � R d i s p l a y   d i a l o g   d e f a u l t S a v e P a t h A p p l e s c r i p t �  � � � l     ��������  ��  ��   �  � � � l     �� � ���   � , & save to same directory without asking    � � � � L   s a v e   t o   s a m e   d i r e c t o r y   w i t h o u t   a s k i n g �  � � � l     �� � ���   � = 7set fileSave to defaultSavePath & "/" & defaultSaveName    � � � � n s e t   f i l e S a v e   t o   d e f a u l t S a v e P a t h   &   " / "   &   d e f a u l t S a v e N a m e �  � � � l     �� � ���   � #  ask for directory to save to    � � � � :   a s k   f o r   d i r e c t o r y   t o   s a v e   t o �  � � � l  � � ����� � r   � � � � � I  � ����� �
�� .sysonwflfile    ��� null��   � �� � �
�� 
prmt � m   � � � � � � �  S a v e   A s � �� � �
�� 
dfnm � o   � ����� "0 defaultsavename defaultSaveName � �� ���
�� 
dflc � o   � ��� 80 defaultsavepathapplescript defaultSavePathApplescript��   � o      �~�~ 0 filesave fileSave��  ��   �  � � � l     �} � ��}   �  display dialog fileSave    � � � � . d i s p l a y   d i a l o g   f i l e S a v e �  � � � l  � � ��|�{ � r   � � � � � n   � � �  � 1   � ��z
�z 
psxp  o   � ��y�y 0 filesave fileSave � o      �x�x 0 filesave fileSave�|  �{   �  l  � ��w�v Z  � ��u�t H   � � D   � � o   � ��s�s 0 filesave fileSave m   � �		 �

  . t a r . g z r   � � b   � � o   � ��r�r 0 filesave fileSave m   � � �  . t a r . g z o      �q�q 0 filesave fileSave�u  �t  �w  �v    l     �p�p    display dialog fileSave    � . d i s p l a y   d i a l o g   f i l e S a v e  l     �o�n�m�o  �n  �m    l  ��l�k r   � n   �	 1  	�j
�j 
strq n   �  1  �i
�i 
psxp  o   ��h�h 0 filesave fileSave o      �g�g 0 opp  �l  �k   !"! l     �f#$�f  #  display dialog opp   $ �%% $ d i s p l a y   d i a l o g   o p p" &'& l     �e�d�c�e  �d  �c  ' ()( l     �b*+�b  * > 8 testing if file already exists, macos does that already   + �,, p   t e s t i n g   i f   f i l e   a l r e a d y   e x i s t s ,   m a c o s   d o e s   t h a t   a l r e a d y) -.- l     �a/0�a  / $ set testFileExists to fileSave   0 �11 < s e t   t e s t F i l e E x i s t s   t o   f i l e S a v e. 232 l     �`45�`  4  tell application "Finder"   5 �66 2 t e l l   a p p l i c a t i o n   " F i n d e r "3 787 l     �_9:�_  9 ) #	if exists file testFileExists then   : �;; F 	 i f   e x i s t s   f i l e   t e s t F i l e E x i s t s   t h e n8 <=< l     �^>?�^  > r l		set question to display dialog "file already exists, overwrite it?" buttons {"Yes", "No"} default button 2   ? �@@ � 	 	 s e t   q u e s t i o n   t o   d i s p l a y   d i a l o g   " f i l e   a l r e a d y   e x i s t s ,   o v e r w r i t e   i t ? "   b u t t o n s   { " Y e s " ,   " N o " }   d e f a u l t   b u t t o n   2= ABA l     �]CD�]  C 1 +		set answer to button returned of question   D �EE V 	 	 s e t   a n s w e r   t o   b u t t o n   r e t u r n e d   o f   q u e s t i o nB FGF l     �\HI�\  H ! 		if (answer is "Yes") then   I �JJ 6 	 	 i f   ( a n s w e r   i s   " Y e s " )   t h e nG KLK l     �[MN�[  M Z T			do shell script "cd \"$(dirname " & opp & ")\" && rm \"$(basename " & opp & ")\""   N �OO � 	 	 	 d o   s h e l l   s c r i p t   " c d   \ " $ ( d i r n a m e   "   &   o p p   &   " ) \ "   & &   r m   \ " $ ( b a s e n a m e   "   &   o p p   &   " ) \ " "L PQP l     �ZRS�Z  R  return true   S �TT  r e t u r n   t r u eQ UVU l     �YWX�Y  W  		else   X �YY  	 	 e l s eV Z[Z l     �X\]�X  \  			return false   ] �^^  	 	 	 r e t u r n   f a l s e[ _`_ l     �Wab�W  a  		end if   b �cc  	 	 e n d   i f` ded l     �Vfg�V  f  	else   g �hh 
 	 e l s ee iji l     �Ukl�U  k  return false   l �mm  r e t u r n   f a l s ej non l     �Tpq�T  p  	end if   q �rr  	 e n d   i fo sts l     �Suv�S  u  end tell   v �ww  e n d   t e l lt xyx l     �R�Q�P�R  �Q  �P  y z{z l     �O|}�O  |   checking dependencies   } �~~ ,   c h e c k i n g   d e p e n d e n c i e s{ � l     �N���N  � ! set dependencycheckok to ""   � ��� 6 s e t   d e p e n d e n c y c h e c k o k   t o   " "� ��� l  ��M�L� r   ��� J  �� ��� m  �� ���  g n u - t a r� ��� m  �� ���  p i g z� ��� m  �� ���  p v� ��K� m  �� ���  c o r e u t i l s�K  � o      �J�J 0 dependencies  �M  �L  � ��� l !.��I�H� I !.�G��
�G .sysonotfnull��� ��� TEXT� m  !$�� ���  . . .� �F��E
�F 
appr� m  '*�� ��� 8 C h e c k i n g   s c r i p t   d e p e n d e n c i e s�E  �I  �H  � ��� l     �D�C�B�D  �C  �B  � ��� l /���A�@� X  /���?�� k  E}�� ��� r  EL��� m  EH�� ���  � o      �>�> 0 dependencycheckok  � ��� r  M^��� I MZ�=��<
�= .sysoexecTEXT���     TEXT� b  MV��� b  MR��� m  MP�� ��� b i f   [ [   $ ( $ ( $ S H E L L   - i   - c   ' w h i c h   b r e w ' )   l i s t   |   g r e p  � o  PQ�;�; 0 
dependency  � m  RU�� ��� V )   = =   ' '   ] ] ;   t h e n   e c h o   n o ;   e l s e   e c h o   y e s ;   f i�<  � o      �:�: 0 dependencycheckok  � ��9� Z  _}���8�� = _f��� o  _b�7�7 0 dependencycheckok  � m  be�� ���  n o� k  iy�� ��� I iv�6��5
�6 .sysodlogaskr        TEXT� b  ir��� b  in��� m  il�� ��� " h o m e b r e w   f o r m u l a  � o  lm�4�4 0 
dependency  � m  nq�� ��� .   i s   m i s s i n g ,   e x i t i n g . . .�5  � ��3� L  wy�2�2  �3  �8  � k  ||�� ��� l ||�1���1  � " display dialog "all good..."   � ��� 8 d i s p l a y   d i a l o g   " a l l   g o o d . . . "� ��0� l ||�/���/  �  -   � ���  -�0  �9  �? 0 
dependency  � o  25�.�. 0 dependencies  �A  �@  � ��� l ����-�,� I ���+��
�+ .sysonotfnull��� ��� TEXT� m  ���� ���  d o n e   ; )� �*��)
�* 
appr� m  ���� ��� 8 C h e c k i n g   s c r i p t   d e p e n d e n c i e s�)  �-  �,  � ��� l     �(�'�&�(  �'  �&  � ��� l     �%���%  � !  getting size of file/foder   � ��� 6   g e t t i n g   s i z e   o f   f i l e / f o d e r� ��� l ����$�#� r  ����� I ���"��!
�" .sysoexecTEXT���     TEXT� b  ����� b  ����� b  ����� b  ����� m  ���� ��� f e c h o   $ ( $ ( $ S H E L L   - i   - c   ' w h i c h   g d u ' )   - s c b   " $ ( d i r n a m e  � o  ��� �  0 ipp  � m  ���� ���  ) " / " $ ( b a s e n a m e  � o  ���� 0 ipp  � m  ��   � � ) "   |   t a i l   - 1   |   a w k   ' { p r i n t   $ 1 } '   |   w h i l e   r e a d   i   ;   d o   e c h o   $ ( e c h o   " $ i * 1 . 0 "   |   b c   |   c u t   - d ' . '   - f 1     )   ;   d o n e )�!  � o      �� 
0 pvsize  �$  �#  �  l     ��    display dialog pvsize    � * d i s p l a y   d i a l o g   p v s i z e  l     �	
�  	  return   
 �  r e t u r n  l     ����  �  �    l �0�� Z  �0� = �� n  �� 1  ���
� 
prun m  ���                                                                                      @ alis    J  macintosh_hd                   BD ����Terminal.app                                                   ����            ����  
 cu             	Utilities   -/:System:Applications:Utilities:Terminal.app/     T e r m i n a l . a p p    m a c i n t o s h _ h d  *System/Applications/Utilities/Terminal.app  / ��   m  ���
� boovtrue O  � k  �  I �����
� .miscactvnull��� ��� null�  �    I ��� �
� .sysodelanull��� ��� nmbr  m  ���� �   !"! Z  �#$�%# = ��&'& l ��(��( I ���
)�	
�
 .corecnte****       ****) 2 ���
� 
cwin�	  �  �  ' m  ����  $ k  ��** +,+ I �����
� .aevtrappnull��� ��� null�  �  , -.- I �����
� .miscactvnull��� ��� null�  �  . /0/ l ��� 12�   1 J Dtell application "System Events" to keystroke "n" using command down   2 �33 � t e l l   a p p l i c a t i o n   " S y s t e m   E v e n t s "   t o   k e y s t r o k e   " n "   u s i n g   c o m m a n d   d o w n0 4��4 I ����5��
�� .sysodelanull��� ��� nmbr5 m  ��66 ?���������  ��  �  % k  �77 898 O �:;: I ���<=
�� .prcskprsnull���     ctxt< m  ��>> �??  n= ��@��
�� 
faal@ J  �AA BCB m  ����
�� eMdsKoptC D��D m  ���
�� eMdsKcmd��  ��  ; m  ��EE�                                                                                  sevs  alis    \  macintosh_hd                   BD ����System Events.app                                              ����            ����  
 cu             CoreServices  0/:System:Library:CoreServices:System Events.app/  $  S y s t e m   E v e n t s . a p p    m a c i n t o s h _ h d  -System/Library/CoreServices/System Events.app   / ��  9 F��F I 	��G��
�� .sysodelanull��� ��� nmbrG m  	HH ?���������  ��  " I��I I ��J��
�� .sysodelanull��� ��� nmbrJ m  KK ?�      ��  ��   m  ��LL�                                                                                      @ alis    J  macintosh_hd                   BD ����Terminal.app                                                   ����            ����  
 cu             	Utilities   -/:System:Applications:Utilities:Terminal.app/     T e r m i n a l . a p p    m a c i n t o s h _ h d  *System/Applications/Utilities/Terminal.app  / ��  �   O  0MNM k  "/OO PQP I "'������
�� .miscactvnull��� ��� null��  ��  Q R��R I (/��S��
�� .sysodelanull��� ��� nmbrS m  (+TT ?�      ��  ��  N m  UU�                                                                                      @ alis    J  macintosh_hd                   BD ����Terminal.app                                                   ����            ����  
 cu             	Utilities   -/:System:Applications:Utilities:Terminal.app/     T e r m i n a l . a p p    m a c i n t o s h _ h d  *System/Applications/Utilities/Terminal.app  / ��  �  �   VWV l     ��������  ��  ��  W XYX l 1�Z����Z O  1�[\[ k  7�]] ^_^ I 7<������
�� .miscactvnull��� ��� null��  ��  _ `a` l ==��bc��  b J Dtell application "System Events" to keystroke "t" using command down   c �dd � t e l l   a p p l i c a t i o n   " S y s t e m   E v e n t s "   t o   k e y s t r o k e   " t "   u s i n g   c o m m a n d   d o w na efe l ==��gh��  g L Frepeat while contents of selected tab of window 1 starts with linefeed   h �ii � r e p e a t   w h i l e   c o n t e n t s   o f   s e l e c t e d   t a b   o f   w i n d o w   1   s t a r t s   w i t h   l i n e f e e df jkj l ==��lm��  l  
	delay 1.5   m �nn  	 d e l a y   1 . 5k opo l ==��qr��  q  
end repeat   r �ss  e n d   r e p e a tp tut l ==��������  ��  ��  u vwv I =D��x��
�� .sysodelanull��� ��� nmbrx m  =@yy ?�      ��  w z{z l EE��|}��  | E ? using which to detect the install path of the homebrew command   } �~~ ~   u s i n g   w h i c h   t o   d e t e c t   t h e   i n s t a l l   p a t h   o f   t h e   h o m e b r e w   c o m m a n d{ � I E�����
�� .coredoscnull��� ��� ctxt� b  E���� b  E���� b  E���� b  E���� b  E���� b  E|��� b  Ex��� b  Et��� b  Ep��� b  El��� b  Eh��� b  Ed��� b  E`��� b  E\��� b  EX��� b  ET��� b  EP��� b  EL��� m  EH�� ��� � p r i n t f   ' \ e c '   & &   e c h o   ' '   & &   e c h o   - e   ' \ 0 3 3 [ 1 m s t a r t i n g   a r c h i v i n g . . . \ 0 3 3 [ 0 m ' ;   e c h o   ' ' ;   e c h o   a r c h i v i n g   " $ ( d i r n a m e  � o  HK���� 0 ipp  � m  LO�� ���  ) " / " $ ( b a s e n a m e  � o  PS���� 0 ipp  � m  TW�� ��� @ ) " / ; p r i n t f   ' % - 1 0 s '   ' t o '   " $ ( e c h o  � o  X[���� 0 opp  � m  \_�� ��� : ) "   & &   e c h o ;   p u s h d   " $ ( d i r n a m e  � o  `c���� 0 ipp  � m  dg�� ��� R ) "   1 >   / d e v / n u l l ;   g t a r   - c p f   -   " $ ( b a s e n a m e  � o  hk���� 0 ipp  � m  lo�� ���  ) "   |   p v   - s  � o  ps���� 
0 pvsize  � m  tw�� ��� 2   |   p i g z   - - b e s t   >   " $ ( e c h o  � o  x{���� 0 opp  � m  |�� ��� � ) " ;   p o p d   1 >   / d e v / n u l l   & &   e c h o   ' '   & &   e c h o   ' t e s t i n g   i n t e g r i t y   o f   f i l e ( s ) '   & &   e c h o   ' '   & &   e c h o   - n   " $ ( b a s e n a m e  � o  ������ 0 opp  � m  ���� ��� < ) " ' . . .   '   & &   u n p i g z   - c   " $ ( e c h o  � o  ������ 0 opp  � m  ���� ��� � ) "   |   g t a r   - t v v   > / d e v / n u l l   2 > & 1   & &   e c h o   - e   ' f i l e   i s   \ 0 3 3 [ 1 ; 3 2 m O K \ 0 3 3 [ 0 m '   | |   e c h o   - e   ' f i l e   i s   \ 0 3 3 [ 1 ; 3 1 m I N V A L I D \ 0 3 3 [ 0 m ' ;   e c h o   ' '� �����
�� 
kfil� n  ����� 1  ����
�� 
tcnt� 4 �����
�� 
cwin� m  ������ ��  � ���� l ����������  ��  ��  ��  \ m  14���                                                                                      @ alis    J  macintosh_hd                   BD ����Terminal.app                                                   ����            ����  
 cu             	Utilities   -/:System:Applications:Utilities:Terminal.app/     T e r m i n a l . a p p    m a c i n t o s h _ h d  *System/Applications/Utilities/Terminal.app  / ��  ��  ��  Y ��� l     ��������  ��  ��  � ��� l     ��������  ��  ��  � ��� l     ������  �  ## documentation   � ���   # #   d o c u m e n t a t i o n� ��� l     ������  � !  \" keeping spaces alive \"   � ��� 6   \ "   k e e p i n g   s p a c e s   a l i v e   \ "� ��� l     ��������  ��  ��  � ��� l     ������  � E ? using which to detect the install path of the homebrew command   � ��� ~   u s i n g   w h i c h   t o   d e t e c t   t h e   i n s t a l l   p a t h   o f   t h e   h o m e b r e w   c o m m a n d� ��� l     ��������  ��  ��  � ��� l     ������  � ? 9 use SHELL -i -c in do shell script (sources config file)   � ��� r   u s e   S H E L L   - i   - c   i n   d o   s h e l l   s c r i p t   ( s o u r c e s   c o n f i g   f i l e )� ��� l     ������  � y s use SHELL -l -c or just the command in do script (as it is run in terminal and sources config files automatically)   � ��� �   u s e   S H E L L   - l   - c   o r   j u s t   t h e   c o m m a n d   i n   d o   s c r i p t   ( a s   i t   i s   r u n   i n   t e r m i n a l   a n d   s o u r c e s   c o n f i g   f i l e s   a u t o m a t i c a l l y )� ��� l     ��������  ��  ��  � ��� l     ������  �   cd to directory   � ���     c d   t o   d i r e c t o r y� ��� l     ��������  ��  ��  � ��� l     ������  � 2 , cat virtualbox.tar.gz.* > virtualbox.tar.gz   � ��� X   c a t   v i r t u a l b o x . t a r . g z . *   >   v i r t u a l b o x . t a r . g z� ��� l     ������  � , & pigz -dc virtualbox.tar.gz | tar xf -   � ��� L   p i g z   - d c   v i r t u a l b o x . t a r . g z   |   t a r   x f   -� ��� l     ��������  ��  ��  � ��� l     ������  � 6 0 cat virtualbox.tar.gz.* | pigz -dc - | tar xf -   � ��� `   c a t   v i r t u a l b o x . t a r . g z . *   |   p i g z   - d c   -   |   t a r   x f   -� ��� l     ������  � - ' cat *.tar.gz.* | pigz -dc - | tar xf -   � �   N   c a t   * . t a r . g z . *   |   p i g z   - d c   -   |   t a r   x f   -�  l     ����   E ? cat *.tar.gz.* | pigz -dc - | tar -C /Users/tom/Desktop/ -xf -    � ~   c a t   * . t a r . g z . *   |   p i g z   - d c   -   |   t a r   - C   / U s e r s / t o m / D e s k t o p /   - x f   -  l     ��	��   � | cat *.tar.gz.* | pv -s $(cat *.tar.gz.* | du -s | awk '{print $1}')"k" | pigz -dc - | tar -C /Users/tom/Desktop/test/ -xf -   	 �

 �   c a t   * . t a r . g z . *   |   p v   - s   $ ( c a t   * . t a r . g z . *   |   d u   - s   |   a w k   ' { p r i n t   $ 1 } ' ) " k "   |   p i g z   - d c   -   |   t a r   - C   / U s e r s / t o m / D e s k t o p / t e s t /   - x f   -  l     ��������  ��  ��    l     ����   4 . cat virtualbox.tar.bz2.* > virtualbox.tar.bz2    � \   c a t   v i r t u a l b o x . t a r . b z 2 . *   >   v i r t u a l b o x . t a r . b z 2  l     ����   / ) pbzip2 -dck virtualbox.tar.gz | tar xf -    � R   p b z i p 2   - d c k   v i r t u a l b o x . t a r . g z   |   t a r   x f   -  l     ��������  ��  ��    l     ����   : 4 cat virtualbox.tar.bz2.* | pbzip2 -dck - | tar xf -    � h   c a t   v i r t u a l b o x . t a r . b z 2 . *   |   p b z i p 2   - d c k   -   |   t a r   x f   -  l     ��������  ��  ��    !  l     ��"#��  " %  brew install pigz coreutils pv   # �$$ >   b r e w   i n s t a l l   p i g z   c o r e u t i l s   p v! %��% l     ��&'��  &    brew install p7zip pbzip2   ' �(( 4   b r e w   i n s t a l l   p 7 z i p   p b z i p 2��       ��)*��  ) ��
�� .aevtoappnull  �   � ***** ��+����,-��
�� .aevtoappnull  �   � ****+ k    �..  //  00   11  K22  �33  �44  �55  �66  �77  �88  �99 :: ;; �<< �== �>> �?? �@@ AA X����  ��  ��  , ���� 0 
dependency  - c����  ���� )�� .������ V e���������� o �� �� ��~�}�|�{ � ��z�y � ��x�w�v�u ��t�s�r�q�p	�o�����n��m��l�k�j�i��h��������� �g�f�e�d�c6>�b�a�`�_Ky�����������^�]�\
�� misccura
�� .miscactvnull��� ��� null��  0 thechoiceslist theChoicesList
�� 
prmp
�� 
inSL�� 
�� .gtqpchltns    @   @ ns  �� 0 	inputtype 	inputType
�� 
dflc
�� afdrdesk
�� .earsffdralis        afdr
�� .sysostdfalis    ��� null�� 0 	inputitem 	inputItem
�� .sysostflalis    ��� null
� .sysodlogaskr        TEXT
�~ 
posx�}  0 posixinputitem posixinputItem
�| 
strq�{ 0 ipp  
�z .sysoexecTEXT���     TEXT�y "0 defaultsavename defaultSaveName�x "0 defaultsavepath defaultSavePath
�w 
psxf�v 80 defaultsavepathapplescript defaultSavePathApplescript
�u 
prmt
�t 
dfnm�s 
�r .sysonwflfile    ��� null�q 0 filesave fileSave
�p 
psxp�o 0 opp  �n 0 dependencies  
�m 
appr
�l .sysonotfnull��� ��� TEXT
�k 
kocl
�j 
cobj
�i .corecnte****       ****�h 0 dependencycheckok  �g 
0 pvsize  
�f 
prun
�e .sysodelanull��� ��� nmbr
�d 
cwin
�c .aevtrappnull��� ��� null
�b 
faal
�a eMdsKopt
�` eMdsKcmd
�_ .prcskprsnull���     ctxt
�^ 
kfil
�] 
tcnt
�\ .coredoscnull��� ��� ctxt���� *j UO��lvE�O�����kv� 
E�O��kv  *����j � E` Y ,�a kv  *�a ��j � E` Y a j OhOa  _ a ,E` UO_ a ,E` Oa _ %a %j E`  Oa !_ %a "%j E` #O*a $_ #/E` %O*a &a 'a (_  �_ %a ) *E` +O_ +a ,,E` +O_ +a - _ +a .%E` +Y hO_ +a ,,a ,E` /Oa 0a 1a 2a 3�vE` 4Oa 5a 6a 7l 8O R_ 4[a 9a :l ;kh  a <E` =Oa >�%a ?%j E` =O_ =a @  a A�%a B%j OhY h[OY��Oa Ca 6a Dl 8Oa E_ %a F%_ %a G%j E` HOa Ia J,e  ea I [*j Okj KO*a L-j ;j  *j MO*j Oa Nj KY #a  a Oa Pa Qa Rlvl SUOa Nj KOa Tj KUY a I *j Oa Tj KUOa I n*j Oa Uj KOa V_ %a W%_ %a X%_ /%a Y%_ %a Z%_ %a [%_ H%a \%_ /%a ]%_ /%a ^%_ /%a _%a `*a Lk/a a,l bOPU ascr  ��ޭ