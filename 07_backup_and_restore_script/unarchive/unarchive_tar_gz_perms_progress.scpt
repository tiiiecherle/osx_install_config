FasdUAS 1.101.10   ��   ��    k             l     ��  ��     tell application "Finder"     � 	 	 2 t e l l   a p p l i c a t i o n   " F i n d e r "   
  
 l     ����  r         l     ����  I    ���� 
�� .sysostdfalis    ��� null��    ��  
�� 
prmp  m       �   8 S e l e c t   a   f i l e   t o   b e   u n p a c k e d  �� ��
�� 
dflc  I   	�� ��
�� .earsffdralis        afdr  m    ��
�� afdrdesk��  ��  ��  ��    o      ���� 0 	inputfile 	inputFile��  ��        l    ����  O       r        n        1    ��
�� 
posx  o    ���� 0 	inputfile 	inputFile  o      ����  0 posixinputfile posixinputFile  m        �                                                                                  sevs  alis    ^  macintosh_hd2                  BD ����System Events.app                                              ����            ����  
 cu             CoreServices  0/:System:Library:CoreServices:System Events.app/  $  S y s t e m   E v e n t s . a p p    m a c i n t o s h _ h d 2  -System/Library/CoreServices/System Events.app   / ��  ��  ��     ! " ! l     #���� # r      $ % $ n     & ' & 1    ��
�� 
strq ' o    ����  0 posixinputfile posixinputFile % o      ���� 0 ipp  ��  ��   "  ( ) ( l     ��������  ��  ��   )  * + * l  ! . ,���� , r   ! . - . - l  ! * /���� / I  ! *�� 0��
�� .sysoexecTEXT���     TEXT 0 b   ! & 1 2 1 b   ! $ 3 4 3 m   ! " 5 5 � 6 6 " e c h o   " $ ( b a s e n a m e   4 o   " #���� 0 ipp   2 m   $ % 7 7 � 8 8 @   |   r e v   |   c u t   - d ' . '   - f - 2   |   r e v   ) "��  ��  ��   . o      ����  0 fileextensions fileExtensions��  ��   +  9 : 9 l  / G ;���� ; Z   / G < =�� > < l  / 6 ?���� ? =  / 6 @ A @ o   / 2����  0 fileextensions fileExtensions A m   2 5 B B � C C  t a r . g z��  ��   = k   9 9 D D  E F E l  9 9�� G H��   G # display dialog fileExtensions    H � I I : d i s p l a y   d i a l o g   f i l e E x t e n s i o n s F  J�� J l  9 9�� K L��   K   tar.gz    L � M M    t a r . g z��  ��   > k   = G N N  O P O I  = D�� Q��
�� .sysodlogaskr        TEXT Q m   = @ R R � S S � W r o n g   f i l e t y p e ,   p l e a s e   s e l e c t   t h e   f i r s t   f i l e   o f   t h e   a r c h i v e   e n d i n g   w i t h   . t a r . g z��   P  T�� T L   E G U U m   E F��
�� boovfals��  ��  ��   :  V W V l     ��������  ��  ��   W  X Y X l  H Y Z���� Z r   H Y [ \ [ l  H U ]���� ] I  H U�� ^��
�� .sysoexecTEXT���     TEXT ^ b   H Q _ ` _ b   H M a b a m   H K c c � d d " e c h o   " $ ( b a s e n a m e   b o   K L���� 0 ipp   ` m   M P e e � f f @   |   r e v   |   c u t   - d ' . '   - f 3 -   |   r e v   ) "��  ��  ��   \ o      ���� 0 newfoldername newFolderName��  ��   Y  g h g l     �� i j��   i " display dialog newFolderName    j � k k 8 d i s p l a y   d i a l o g   n e w F o l d e r N a m e h  l m l l     �� n o��   n  	 filename    o � p p    f i l e n a m e m  q r q l     ��������  ��  ��   r  s t s l  Z k u���� u r   Z k v w v l  Z g x���� x I  Z g�� y��
�� .sysoexecTEXT���     TEXT y b   Z c z { z b   Z _ | } | m   Z ] ~ ~ �   " e c h o   " $ ( b a s e n a m e   } o   ] ^���� 0 ipp   { m   _ b � � � � � @   |   r e v   |   c u t   - d ' . '   - f 1 -   |   r e v   ) "��  ��  ��   w o      ���� $0 filenamenosuffix filenameNoSuffix��  ��   t  � � � l     �� � ���   �   filename.tar.gz    � � � �     f i l e n a m e . t a r . g z �  � � � l     �� � ���   � % display dialog filenameNoSuffix    � � � � > d i s p l a y   d i a l o g   f i l e n a m e N o S u f f i x �  � � � l     ��������  ��  ��   �  � � � l  l y ����� � r   l y � � � I  l u���� �
�� .sysostflalis    ��� null��   � �� ���
�� 
prmp � m   n q � � � � � 0 S e l e c t   t h e   o u t p u t   f o l d e r��   � o      ���� 0 outputfolder outputFolder��  ��   �  � � � l  z � ����� � r   z � � � � n   z � � � � 1   � ���
�� 
strq � n   z � � � � 1   } ���
�� 
psxp � o   z }���� 0 outputfolder outputFolder � o      ���� 0 opp  ��  ��   �  � � � l  � � ����� � r   � � � � � b   � � � � � b   � � � � � l  � � ����� � c   � � � � � o   � ����� 0 outputfolder outputFolder � m   � ���
�� 
ctxt��  ��   � o   � ����� 0 newfoldername newFolderName � m   � � � � � � �  : � o      ���� $0 testfolderexists testFolderExists��  ��   �  � � � l     ��������  ��  ��   �  � � � l     �� � ���   �   checking dependencies    � � � � ,   c h e c k i n g   d e p e n d e n c i e s �  � � � l     �� � ���   � ! set dependencycheckok to ""    � � � � 6 s e t   d e p e n d e n c y c h e c k o k   t o   " " �  � � � l  � � ����� � r   � � � � � J   � � � �  � � � m   � � � � � � �  g n u - t a r �  � � � m   � � � � � � �  p i g z �  � � � m   � � � � � � �  p v �  ��� � m   � � � � � � �  c o r e u t i l s��   � o      ���� 0 dependencies  ��  ��   �  � � � l  � � ����� � I  � ��� � �
�� .sysonotfnull��� ��� TEXT � m   � � � � � � �  . . . � �� ���
�� 
appr � m   � � � � � � � 8 C h e c k i n g   s c r i p t   d e p e n d e n c i e s��  ��  ��   �  � � � l     ��������  ��  ��   �  � � � l  � ����� � X   � ��� � � k   � � �  � � � r   � � � � � m   � � � � � � �   � o      ���� 0 dependencycheckok   �  � � � r   � � � � � I  � ��� ���
�� .sysoexecTEXT���     TEXT � b   � � � � � b   � � � � � m   � � � � � � � b i f   [ [   $ ( $ ( $ S H E L L   - i   - c   ' w h i c h   b r e w ' )   l i s t   |   g r e p   � o   � ����� 0 
dependency   � m   � � � � � � � V )   = =   ' '   ] ] ;   t h e n   e c h o   n o ;   e l s e   e c h o   y e s ;   f i��   � o      ���� 0 dependencycheckok   �  ��� � Z   � � ��� � � =  � � � � � o   � ����� 0 dependencycheckok   � m   � � � � � � �  n o � k   � � �  � � � I  ��� ��
�� .sysodlogaskr        TEXT � b   �    b   � � m   � � � " h o m e b r e w   f o r m u l a   o   � ��~�~ 0 
dependency   m   � � � .   i s   m i s s i n g ,   e x i t i n g . . .�   � �} L  �|�|  �}  ��   � k  

		 

 l 

�{�{   " display dialog "all good..."    � 8 d i s p l a y   d i a l o g   " a l l   g o o d . . . " �z l 

�y�y    -    �  -�z  ��  �� 0 
dependency   � o   � ��x�x 0 dependencies  ��  ��   �  l �w�v I �u
�u .sysonotfnull��� ��� TEXT m   �  d o n e   ; ) �t�s
�t 
appr m   � 8 C h e c k i n g   s c r i p t   d e p e n d e n c i e s�s  �w  �v    l     �r�q�p�r  �q  �p     l �!�o�n! O  �"#" Z  %�$%�m&$ I %1�l'�k
�l .coredoexnull���     obj ' 4  %-�j(
�j 
cfol( o  ),�i�i $0 testfolderexists testFolderExists�k  % k  4�)) *+* r  4N,-, I 4J�h./
�h .sysodlogaskr        TEXT. m  4700 �11 H f o l d e r   a l r e a d y   e x i s t s ,   o v e r w r i t e   i t ?/ �g23
�g 
btns2 J  :B44 565 m  :=77 �88  Y e s6 9�f9 m  =@:: �;;  N o�f  3 �e<�d
�e 
dflt< m  EF�c�c �d  - o      �b�b 0 question  + =>= r  OZ?@? n  OVABA 1  RV�a
�a 
bhitB o  OR�`�` 0 question  @ o      �_�_ 
0 answer  > C�^C Z  [�DE�]FD l [bG�\�[G = [bHIH o  [^�Z�Z 
0 answer  I m  ^aJJ �KK  Y e s�\  �[  E k  e�LL MNM l ee�YOP�Y  O $ display dialog "answer is yes"   P �QQ < d i s p l a y   d i a l o g   " a n s w e r   i s   y e s "N RSR I e��XT�W
�X .sysoexecTEXT���     TEXTT b  e�UVU b  e|WXW b  exYZY b  et[\[ b  ep]^] b  el_`_ m  ehaa �bb  c d   " $ ( d i r n a m e  ` o  hk�V�V 0 opp  ^ m  locc �dd  ) " / " $ ( b a s e n a m e  \ o  ps�U�U 0 opp  Z m  twee �ff , ) " /   & &   r m   - r f   " $ ( e c h o  X o  x{�T�T 0 newfoldername newFolderNameV m  |gg �hh  ) "�W  S i�Si l ���Rjk�R  j  return true   k �ll  r e t u r n   t r u e�S  �]  F L  ��mm m  ���Q
�Q boovfals�^  �m  & l ���Pno�P  n  return false   o �pp  r e t u r n   f a l s e# m  "qq�                                                                                  MACS  alis    B  macintosh_hd2                  BD ����
Finder.app                                                     ����            ����  
 cu             CoreServices  )/:System:Library:CoreServices:Finder.app/    
 F i n d e r . a p p    m a c i n t o s h _ h d 2  &System/Library/CoreServices/Finder.app  / ��  �o  �n    rsr l     �O�N�M�O  �N  �M  s tut l �v�L�Kv Z  �wx�Jyw = ��z{z n  ��|}| 1  ���I
�I 
prun} m  ��~~�                                                                                      @ alis    L  macintosh_hd2                  BD ����Terminal.app                                                   ����            ����  
 cu             	Utilities   -/:System:Applications:Utilities:Terminal.app/     T e r m i n a l . a p p    m a c i n t o s h _ h d 2  *System/Applications/Utilities/Terminal.app  / ��  { m  ���H
�H boovtruex O  ��� k  ���� ��� I ���G�F�E
�G .miscactvnull��� ��� null�F  �E  � ��� I ���D��C
�D .sysodelanull��� ��� nmbr� m  ���B�B �C  � ��� Z  �����A�� = ����� l ����@�?� I ���>��=
�> .corecnte****       ****� 2 ���<
�< 
cwin�=  �@  �?  � m  ���;�;  � k  ���� ��� I ���:�9�8
�: .aevtrappnull��� ��� null�9  �8  � ��� I ���7�6�5
�7 .miscactvnull��� ��� null�6  �5  � ��� l ���4���4  � J Dtell application "System Events" to keystroke "n" using command down   � ��� � t e l l   a p p l i c a t i o n   " S y s t e m   E v e n t s "   t o   k e y s t r o k e   " n "   u s i n g   c o m m a n d   d o w n� ��3� I ���2��1
�2 .sysodelanull��� ��� nmbr� m  ���� ?��������1  �3  �A  � k  ���� ��� O ����� I ���0��
�0 .prcskprsnull���     ctxt� m  ���� ���  n� �/��.
�/ 
faal� J  ���� ��� m  ���-
�- eMdsKopt� ��,� m  ���+
�+ eMdsKcmd�,  �.  � m  �����                                                                                  sevs  alis    ^  macintosh_hd2                  BD ����System Events.app                                              ����            ����  
 cu             CoreServices  0/:System:Library:CoreServices:System Events.app/  $  S y s t e m   E v e n t s . a p p    m a c i n t o s h _ h d 2  -System/Library/CoreServices/System Events.app   / ��  � ��*� I ���)��(
�) .sysodelanull��� ��� nmbr� m  ���� ?��������(  �*  � ��'� I ���&��%
�& .sysodelanull��� ��� nmbr� m  ���� ?�      �%  �'  � m  �����                                                                                      @ alis    L  macintosh_hd2                  BD ����Terminal.app                                                   ����            ����  
 cu             	Utilities   -/:System:Applications:Utilities:Terminal.app/     T e r m i n a l . a p p    m a c i n t o s h _ h d 2  *System/Applications/Utilities/Terminal.app  / ��  �J  y O  ���� k  �� ��� I 	�$�#�"
�$ .miscactvnull��� ��� null�#  �"  � ��!� I 
� ��
�  .sysodelanull��� ��� nmbr� m  
�� ?�      �  �!  � m  ����                                                                                      @ alis    L  macintosh_hd2                  BD ����Terminal.app                                                   ����            ����  
 cu             	Utilities   -/:System:Applications:Utilities:Terminal.app/     T e r m i n a l . a p p    m a c i n t o s h _ h d 2  *System/Applications/Utilities/Terminal.app  / ��  �L  �K  u ��� l     ����  �  �  � ��� l ����� O  ���� k  ��� ��� I ���
� .miscactvnull��� ��� null�  �  � ��� I &���
� .sysodelanull��� ��� nmbr� m  "�� ?�      �  � ��� l ''����  �  �  � ��� r  '���� I '����
� .coredoscnull��� ��� ctxt� b  '|��� b  'x��� b  't��� b  'p��� b  'l��� b  'h��� b  'd��� b  '`��� b  '^��� b  'Z��� b  'V��� b  'R��� b  'P��� b  'L��� b  'H��� b  'D��� b  '@��� b  '<��� b  '8��� b  '4��� b  '0��� b  ',��� m  '*�� ���� p r i n t f   ' \ e c '   & &   e c h o   ' '   & &   e c h o   - e   ' \ 0 3 3 [ 1 m s t a r t i n g   u n a r c h i v i n g . . . \ 0 3 3 [ 0 m ' ;   i f   s u d o   - n   t r u e   2 > / d e v / n u l l ;   t h e n   : ;   e l s e   e c h o   ' p l e a s e   e n t e r   s u d o   p a s s w o r d   t o   p r e s e r v e   p e r m i s s i o n s   w h i l e   e x t r a c t i n g : '   & &   s u d o   - v ;   f i ;   e c h o   ' ' ;   e c h o   u n a r c h i v i n g   " $ ( d i r n a m e  � o  *+�� 0 ipp  � m  ,/   �  ) " / " $ ( e c h o  � o  03�� $0 filenamenosuffix filenameNoSuffix� m  47 � F ) " ;   p r i n t f   ' % - 1 2 s '   ' t o '   " $ ( d i r n a m e  � o  8;�� 0 opp  � m  <? �  ) " / " $ ( b a s e n a m e  � o  @C�� 0 opp  � m  DG �  ) " / " $ ( e c h o  � o  HK�� 0 newfoldername newFolderName� m  LO �		 H ) "   & &   e c h o ;   e c h o   ' ' ;   c a t   " $ ( d i r n a m e  � o  PQ�� 0 ipp  � m  RU

 �  ) " / " $ ( e c h o  � o  VY�
�
 $0 filenamenosuffix filenameNoSuffix� m  Z] � B ) "   |   p v   - s   $ ( g d u   - s c b   " $ ( d i r n a m e  � o  ^_�	�	 0 ipp  � m  `c �  ) " / " $ ( e c h o  � o  dg�� $0 filenamenosuffix filenameNoSuffix� m  hk �6 ) "   |   t a i l   - 1   |   a w k   ' { p r i n t   $ 1 } '   |   w h i l e   r e a d   i   ;   d o   e c h o   $ ( e c h o   " $ i * 1 "   |   b c   |   c u t   - d ' . '   - f 1   )   ;   d o n e   )   |   p i g z   - d c   -   |   s u d o   g t a r   - - s a m e - o w n e r   - C   " $ ( d i r n a m e  � o  lo�� 0 opp  � m  ps �  ) " / " $ ( b a s e n a m e  � o  tw�� 0 opp  � m  x{ �� ) " /   - x p f   - ;   i f   [   $ ?   =   0   ] ;   t h e n   e c h o   ' '   & &   e c h o   - e   ' u n a r c h i v i n g   \ 0 3 3 [ 1 ; 3 2 m S U C C E S S F U L \ 0 3 3 [ 0 m '   & &   e c h o   ' ' ;   e l s e   e c h o   ' '   & &   e c h o   - e   ' a n   \ 0 3 3 [ 1 ; 3 1 m E R R O R \ 0 3 3 [ 0 m   o c c u r e d ,   p l e a s e   u n a r c h i v e   a g a i n . . . '   & &   e c h o   ' ' ;   f i� ��
� 
kfil 4  ��
� 
cwin m  ���� �  � o      �� 0 
currenttab 
currentTab� �  l ����������  ��  ��  �   � m  �                                                                                      @ alis    L  macintosh_hd2                  BD ����Terminal.app                                                   ����            ����  
 cu             	Utilities   -/:System:Applications:Utilities:Terminal.app/     T e r m i n a l . a p p    m a c i n t o s h _ h d 2  *System/Applications/Utilities/Terminal.app  / ��  �  �  �  l     ��������  ��  ��    l     ��������  ��  ��    l     �� !��    !  \" keeping spaces alive \"   ! �"" 6   \ "   k e e p i n g   s p a c e s   a l i v e   \ " #$# l     ��������  ��  ��  $ %&% l     ��'(��  '   cd to directory   ( �))     c d   t o   d i r e c t o r y& *+* l     ��������  ��  ��  + ,-, l     ��./��  . 2 , cat virtualbox.tar.gz.* > virtualbox.tar.gz   / �00 X   c a t   v i r t u a l b o x . t a r . g z . *   >   v i r t u a l b o x . t a r . g z- 121 l     ��34��  3 , & pigz -dc virtualbox.tar.gz | tar xf -   4 �55 L   p i g z   - d c   v i r t u a l b o x . t a r . g z   |   t a r   x f   -2 676 l     ��������  ��  ��  7 898 l     ��:;��  : 6 0 cat virtualbox.tar.gz.* | pigz -dc - | tar xf -   ; �<< `   c a t   v i r t u a l b o x . t a r . g z . *   |   p i g z   - d c   -   |   t a r   x f   -9 =>= l     ��?@��  ? - ' cat *.tar.gz.* | pigz -dc - | tar xf -   @ �AA N   c a t   * . t a r . g z . *   |   p i g z   - d c   -   |   t a r   x f   -> BCB l     ��DE��  D E ? cat *.tar.gz.* | pigz -dc - | tar -C /Users/tom/Desktop/ -xf -   E �FF ~   c a t   * . t a r . g z . *   |   p i g z   - d c   -   |   t a r   - C   / U s e r s / t o m / D e s k t o p /   - x f   -C GHG l     ��IJ��  I � | cat *.tar.gz.* | pv -s $(cat *.tar.gz.* | du -s | awk '{print $1}')"k" | pigz -dc - | tar -C /Users/tom/Desktop/test/ -xf -   J �KK �   c a t   * . t a r . g z . *   |   p v   - s   $ ( c a t   * . t a r . g z . *   |   d u   - s   |   a w k   ' { p r i n t   $ 1 } ' ) " k "   |   p i g z   - d c   -   |   t a r   - C   / U s e r s / t o m / D e s k t o p / t e s t /   - x f   -H LML l     ��������  ��  ��  M NON l     ��������  ��  ��  O PQP l     ��RS��  R 4 . cat virtualbox.tar.bz2.* > virtualbox.tar.bz2   S �TT \   c a t   v i r t u a l b o x . t a r . b z 2 . *   >   v i r t u a l b o x . t a r . b z 2Q UVU l     ��WX��  W / ) pbzip2 -dck virtualbox.tar.gz | tar xf -   X �YY R   p b z i p 2   - d c k   v i r t u a l b o x . t a r . g z   |   t a r   x f   -V Z[Z l     ��������  ��  ��  [ \]\ l     ��^_��  ^ : 4 cat virtualbox.tar.bz2.* | pbzip2 -dck - | tar xf -   _ �`` h   c a t   v i r t u a l b o x . t a r . b z 2 . *   |   p b z i p 2   - d c k   -   |   t a r   x f   -] aba l     ��������  ��  ��  b cdc l     ��������  ��  ��  d e��e l     ��fg��  f / ) brew install pigz coreutils p7zip pbzip2   g �hh R   b r e w   i n s t a l l   p i g z   c o r e u t i l s   p 7 z i p   p b z i p 2��       ��ij��  i ��
�� .aevtoappnull  �   � ****j ��k����lm��
�� .aevtoappnull  �   � ****k k    �nn  
oo  pp  !qq  *rr  9ss  Xtt  suu  �vv  �ww  �xx  �yy  �zz  �{{ || }} t~~ �����  ��  ��  l ���� 0 
dependency  m d�� ������������  �������� 5 7���� B R�� c e�� ~ ��� ����������� ��� � � � ��� ��� ��������� ��� � � �q����0��7:��������Jaceg~����������������������� 
������
�� 
prmp
�� 
dflc
�� afdrdesk
�� .earsffdralis        afdr�� 
�� .sysostdfalis    ��� null�� 0 	inputfile 	inputFile
�� 
posx��  0 posixinputfile posixinputFile
�� 
strq�� 0 ipp  
�� .sysoexecTEXT���     TEXT��  0 fileextensions fileExtensions
�� .sysodlogaskr        TEXT�� 0 newfoldername newFolderName�� $0 filenamenosuffix filenameNoSuffix
�� .sysostflalis    ��� null�� 0 outputfolder outputFolder
�� 
psxp�� 0 opp  
�� 
ctxt�� $0 testfolderexists testFolderExists�� 0 dependencies  
�� 
appr
�� .sysonotfnull��� ��� TEXT
�� 
kocl
�� 
cobj
�� .corecnte****       ****�� 0 dependencycheckok  
�� 
cfol
�� .coredoexnull���     obj 
�� 
btns
�� 
dflt�� 0 question  
�� 
bhit�� 
0 answer  
�� 
prun
�� .miscactvnull��� ��� null
�� .sysodelanull��� ��� nmbr
�� 
cwin
�� .aevtrappnull��� ��� null
�� 
faal
�� eMdsKopt
�� eMdsKcmd
�� .prcskprsnull���     ctxt
�� 
kfil
�� .coredoscnull��� ��� ctxt�� 0 
currenttab 
currentTab���*����j � E�O� ��,E�UO��,E�O��%�%j E` O_ a   hY a j OfOa �%a %j E` Oa �%a %j E` O*�a l E` O_ a ,�,E` O_ a &_ %a  %E` !Oa "a #a $a %�vE` &Oa 'a (a )l *O R_ &[a +a ,l -kh  a .E` /Oa 0�%a 1%j E` /O_ /a 2  a 3�%a 4%j OhY h[OY��Oa 5a (a 6l *Oa 7 l*a 8_ !/j 9 \a :a ;a <a =lva >l� E` ?O_ ?a @,E` AO_ Aa B  &a C_ %a D%_ %a E%_ %a F%j OPY fY hUOa Ga H,e  ca G Y*j IOkj JO*a K-j -j  *j LO*j IOa Mj JY !� a Na Oa Pa Qlvl RUOa Mj JOa Sj JUY a G *j IOa Sj JUOa G x*j IOa Tj JOa U�%a V%_ %a W%_ %a X%_ %a Y%_ %a Z%�%a [%_ %a \%�%a ]%_ %a ^%_ %a _%_ %a `%a a*a Kk/l bE` cOPU ascr  ��ޭ