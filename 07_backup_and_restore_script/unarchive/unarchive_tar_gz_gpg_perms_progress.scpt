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
posx  o    ���� 0 	inputfile 	inputFile  o      ����  0 posixinputfile posixinputFile  m        �                                                                                  sevs  alis    \  macintosh_hd                   BD ����System Events.app                                              ����            ����  
 cu             CoreServices  0/:System:Library:CoreServices:System Events.app/  $  S y s t e m   E v e n t s . a p p    m a c i n t o s h _ h d  -System/Library/CoreServices/System Events.app   / ��  ��  ��     ! " ! l     #���� # r      $ % $ n     & ' & 1    ��
�� 
strq ' o    ����  0 posixinputfile posixinputFile % o      ���� 0 ipp  ��  ��   "  ( ) ( l     ��������  ��  ��   )  * + * l  ! . ,���� , r   ! . - . - l  ! * /���� / I  ! *�� 0��
�� .sysoexecTEXT���     TEXT 0 b   ! & 1 2 1 b   ! $ 3 4 3 m   ! " 5 5 � 6 6 " e c h o   " $ ( b a s e n a m e   4 o   " #���� 0 ipp   2 m   $ % 7 7 � 8 8 @   |   r e v   |   c u t   - d ' . '   - f - 3   |   r e v   ) "��  ��  ��   . o      ����  0 fileextensions fileExtensions��  ��   +  9 : 9 l  / G ;���� ; Z   / G < =�� > < l  / 6 ?���� ? =  / 6 @ A @ o   / 2����  0 fileextensions fileExtensions A m   2 5 B B � C C  t a r . g z . g p g��  ��   = k   9 9 D D  E F E l  9 9�� G H��   G # display dialog fileExtensions    H � I I : d i s p l a y   d i a l o g   f i l e E x t e n s i o n s F  J�� J l  9 9�� K L��   K   tar.gz.gpg    L � M M    t a r . g z . g p g��  ��   > k   = G N N  O P O I  = D�� Q��
�� .sysodlogaskr        TEXT Q m   = @ R R � S S � W r o n g   f i l e t y p e ,   p l e a s e   s e l e c t   t h e   f i r s t   f i l e   o f   t h e   a r c h i v e   e n d i n g   w i t h   . t a r . g z . g p g��   P  T�� T L   E G U U m   E F��
�� boovfals��  ��  ��   :  V W V l     ��������  ��  ��   W  X Y X l  H Y Z���� Z r   H Y [ \ [ l  H U ]���� ] I  H U�� ^��
�� .sysoexecTEXT���     TEXT ^ b   H Q _ ` _ b   H M a b a m   H K c c � d d " e c h o   " $ ( b a s e n a m e   b o   K L���� 0 ipp   ` m   M P e e � f f @   |   r e v   |   c u t   - d ' . '   - f 4 -   |   r e v   ) "��  ��  ��   \ o      ���� 0 newfoldername newFolderName��  ��   Y  g h g l     �� i j��   i " display dialog newFolderName    j � k k 8 d i s p l a y   d i a l o g   n e w F o l d e r N a m e h  l m l l     �� n o��   n  	 filename    o � p p    f i l e n a m e m  q r q l     ��������  ��  ��   r  s t s l  Z k u���� u r   Z k v w v l  Z g x���� x I  Z g�� y��
�� .sysoexecTEXT���     TEXT y b   Z c z { z b   Z _ | } | m   Z ] ~ ~ �   " e c h o   " $ ( b a s e n a m e   } o   ] ^���� 0 ipp   { m   _ b � � � � � @   |   r e v   |   c u t   - d ' . '   - f 1 -   |   r e v   ) "��  ��  ��   w o      ���� (0 filenamewithsuffix filenameWithSuffix��  ��   t  � � � l     �� � ���   �   filename.tar.gz.gpg    � � � � (   f i l e n a m e . t a r . g z . g p g �  � � � l     �� � ���   � ' !display dialog filenameWithSuffix    � � � � B d i s p l a y   d i a l o g   f i l e n a m e W i t h S u f f i x �  � � � l     ��������  ��  ��   �  � � � l  l y ����� � r   l y � � � I  l u���� �
�� .sysostflalis    ��� null��   � �� ���
�� 
prmp � m   n q � � � � � 0 S e l e c t   t h e   o u t p u t   f o l d e r��   � o      ���� 0 outputfolder outputFolder��  ��   �  � � � l  z � ����� � r   z � � � � n   z � � � � 1   � ���
�� 
strq � n   z � � � � 1   } ���
�� 
psxp � o   z }���� 0 outputfolder outputFolder � o      ���� 0 opp  ��  ��   �  � � � l  � � ����� � r   � � � � � b   � � � � � b   � � � � � l  � � ����� � c   � � � � � o   � ����� 0 outputfolder outputFolder � m   � ���
�� 
ctxt��  ��   � o   � ����� 0 newfoldername newFolderName � m   � � � � � � �  : � o      ���� $0 testfolderexists testFolderExists��  ��   �  � � � l     ��������  ��  ��   �  � � � l     �� � ���   �   checking dependencies    � � � � ,   c h e c k i n g   d e p e n d e n c i e s �  � � � l     �� � ���   � ! set dependencycheckok to ""    � � � � 6 s e t   d e p e n d e n c y c h e c k o k   t o   " " �  � � � l  � � ����� � r   � � � � � J   � � � �  � � � m   � � � � � � �  g n u - t a r �  � � � m   � � � � � � �  p i g z �  � � � m   � � � � � � �  p v �  � � � m   � � � � � � �  c o r e u t i l s �  ��� � m   � � � � � � � 
 g n u p g��   � o      ���� 0 dependencies  ��  ��   �  � � � l  � � ����� � I  � ��� � �
�� .sysonotfnull��� ��� TEXT � m   � � � � � � �  . . . � �� ���
�� 
appr � m   � � � � � � � 8 C h e c k i n g   s c r i p t   d e p e n d e n c i e s��  ��  ��   �  � � � l     ��������  ��  ��   �  � � � l  � ����� � X   � ��� � � k   � � �  � � � r   � � � � � m   � � � � � � �   � o      ���� 0 dependencycheckok   �  � � � r   � � � � � I  � ��� ���
�� .sysoexecTEXT���     TEXT � b   � � � � � b   � � � � � m   � � � � � � � b i f   [ [   $ ( $ ( $ S H E L L   - i   - c   ' w h i c h   b r e w ' )   l i s t   |   g r e p   � o   � ����� 0 
dependency   � m   � � � � � � � V )   = =   ' '   ] ] ;   t h e n   e c h o   n o ;   e l s e   e c h o   y e s ;   f i��   � o      ���� 0 dependencycheckok   �  ��� � Z   � � ��� � � =  � � � � � o   � ����� 0 dependencycheckok   � m   � � � � � � �  n o � k   �    I  �	���
�� .sysodlogaskr        TEXT b   � b   � m   � � �		 " h o m e b r e w   f o r m u l a   o   � �~�~ 0 
dependency   m  

 � .   i s   m i s s i n g ,   e x i t i n g . . .�   �} L  
�|�|  �}  ��   � k    l �{�{   " display dialog "all good..."    � 8 d i s p l a y   d i a l o g   " a l l   g o o d . . . " �z l �y�y    -    �  -�z  ��  �� 0 
dependency   � o   � ��x�x 0 dependencies  ��  ��   �  l #�w�v I #�u
�u .sysonotfnull��� ��� TEXT m   �  d o n e   ; ) �t�s
�t 
appr m   �   8 C h e c k i n g   s c r i p t   d e p e n d e n c i e s�s  �w  �v   !"! l     �r�q�p�r  �q  �p  " #$# l $�%�o�n% O  $�&'& Z  *�()�m*( I *6�l+�k
�l .coredoexnull���     obj + 4  *2�j,
�j 
cfol, o  .1�i�i $0 testfolderexists testFolderExists�k  ) k  9�-- ./. r  9S010 I 9O�h23
�h .sysodlogaskr        TEXT2 m  9<44 �55 H f o l d e r   a l r e a d y   e x i s t s ,   o v e r w r i t e   i t ?3 �g67
�g 
btns6 J  ?G88 9:9 m  ?B;; �<<  Y e s: =�f= m  BE>> �??  N o�f  7 �e@�d
�e 
dflt@ m  JK�c�c �d  1 o      �b�b 0 question  / ABA r  T_CDC n  T[EFE 1  W[�a
�a 
bhitF o  TW�`�` 0 question  D o      �_�_ 
0 answer  B G�^G Z  `�HI�]JH l `gK�\�[K = `gLML o  `c�Z�Z 
0 answer  M m  cfNN �OO  Y e s�\  �[  I k  j�PP QRQ l jj�YST�Y  S $ display dialog "answer is yes"   T �UU < d i s p l a y   d i a l o g   " a n s w e r   i s   y e s "R VWV I j��XX�W
�X .sysoexecTEXT���     TEXTX b  j�YZY b  j�[\[ b  j}]^] b  jy_`_ b  juaba b  jqcdc m  jmee �ff  c d   " $ ( d i r n a m e  d o  mp�V�V 0 opp  b m  qtgg �hh  ) " / " $ ( b a s e n a m e  ` o  ux�U�U 0 opp  ^ m  y|ii �jj , ) " /   & &   r m   - r f   " $ ( e c h o  \ o  }��T�T 0 newfoldername newFolderNameZ m  ��kk �ll  ) "�W  W m�Sm l ���Rno�R  n  return true   o �pp  r e t u r n   t r u e�S  �]  J L  ��qq m  ���Q
�Q boovfals�^  �m  * l ���Prs�P  r  return false   s �tt  r e t u r n   f a l s e' m  $'uu�                                                                                  MACS  alis    @  macintosh_hd                   BD ����
Finder.app                                                     ����            ����  
 cu             CoreServices  )/:System:Library:CoreServices:Finder.app/    
 F i n d e r . a p p    m a c i n t o s h _ h d  &System/Library/CoreServices/Finder.app  / ��  �o  �n  $ vwv l     �O�N�M�O  �N  �M  w xyx l �z�L�Kz Z  �{|�J}{ = ��~~ n  ����� 1  ���I
�I 
prun� m  �����                                                                                      @ alis    J  macintosh_hd                   BD ����Terminal.app                                                   ����            ����  
 cu             	Utilities   -/:System:Applications:Utilities:Terminal.app/     T e r m i n a l . a p p    m a c i n t o s h _ h d  *System/Applications/Utilities/Terminal.app  / ��   m  ���H
�H boovtrue| O  � ��� k  ���� ��� I ���G�F�E
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
�+ eMdsKcmd�,  �.  � m  �����                                                                                  sevs  alis    \  macintosh_hd                   BD ����System Events.app                                              ����            ����  
 cu             CoreServices  0/:System:Library:CoreServices:System Events.app/  $  S y s t e m   E v e n t s . a p p    m a c i n t o s h _ h d  -System/Library/CoreServices/System Events.app   / ��  � ��*� I ���)��(
�) .sysodelanull��� ��� nmbr� m  ���� ?��������(  �*  � ��'� I ���&��%
�& .sysodelanull��� ��� nmbr� m  ���� ?�      �%  �'  � m  �����                                                                                      @ alis    J  macintosh_hd                   BD ����Terminal.app                                                   ����            ����  
 cu             	Utilities   -/:System:Applications:Utilities:Terminal.app/     T e r m i n a l . a p p    m a c i n t o s h _ h d  *System/Applications/Utilities/Terminal.app  / ��  �J  } O  ��� k  	�� ��� I 	�$�#�"
�$ .miscactvnull��� ��� null�#  �"  � ��!� I � ��
�  .sysodelanull��� ��� nmbr� m  �� ?�      �  �!  � m  ���                                                                                      @ alis    J  macintosh_hd                   BD ����Terminal.app                                                   ����            ����  
 cu             	Utilities   -/:System:Applications:Utilities:Terminal.app/     T e r m i n a l . a p p    m a c i n t o s h _ h d  *System/Applications/Utilities/Terminal.app  / ��  �L  �K  y ��� l     ����  �  �  � ��� l ����� O  ���� k  ��� ��� I #���
� .miscactvnull��� ��� null�  �  � ��� I $+���
� .sysodelanull��� ��� nmbr� m  $'�� ?�      �  � ��� l ,,����  � L Frepeat while contents of selected tab of window 1 starts with linefeed   � ��� � r e p e a t   w h i l e   c o n t e n t s   o f   s e l e c t e d   t a b   o f   w i n d o w   1   s t a r t s   w i t h   l i n e f e e d� ��� l ,,����  �  
	delay 1.5   � ���  	 d e l a y   1 . 5� ��� l ,,����  �  
end repeat   � ���  e n d   r e p e a t� ��� l ,,����  �   using password upfront   � ��� .   u s i n g   p a s s w o r d   u p f r o n t� ��� l ,,����  ���set currentTab to do script "printf '\\ec' && echo '' && echo -e '\\033[1mstarting decryption and unarchiving...\\033[0m'; if sudo -n true 2>/dev/null; then :; else echo ''; echo 'please enter sudo password to preserve permissions while extracting...' && sudo -v; fi; echo ''; echo 'please enter decryption password...' && stty -echo && trap 'stty echo' EXIT && printf 'gpg decryption password: ' && read -r $@ GPG_PASSWORD && echo '' && stty echo && trap - EXIT && echo '' && echo unarchiving \"$(dirname " & ipp & ")\"/\"$(echo " & filenameWithSuffix & ")\"; printf '%-12s' 'to' \"$(dirname " & opp & ")\"/\"$(basename " & opp & ")\"/\"$(echo " & newFolderName & ")\" && echo; echo ''; cat \"$(dirname " & ipp & ")\"/\"$(echo " & filenameWithSuffix & ")\" | $($SHELL -l -c 'which pv') -s $($($SHELL -l -c 'which gdu') -scb \"$(dirname " & ipp & ")\"/\"$(echo " & filenameWithSuffix & ")\" | tail -1 | awk '{print $1}' | while read i ; do echo $(echo $i*1 | bc | cut -d'.' -f1 ) ; done ) | $($SHELL -l -c 'which gpg') --quiet --batch --no-tty --yes --passphrase=$GPG_PASSWORD -d - | $($SHELL -l -c 'which unpigz') -dc - | sudo $($SHELL -l -c 'which gtar') --same-owner -C \"$(dirname " & opp & ")\"/\"$(basename " & opp & ")\"/ -xpf -; if [ $? = 0 ]; then echo '' && echo -e 'unarchiving \\033[1;32mSUCCESSFUL\\033[0m' && echo ''; else echo '' && echo -e 'an \\033[1;31mERROR\\033[0m occured, please unarchive again...' && echo ''; fi" in window 1   � ���P s e t   c u r r e n t T a b   t o   d o   s c r i p t   " p r i n t f   ' \ \ e c '   & &   e c h o   ' '   & &   e c h o   - e   ' \ \ 0 3 3 [ 1 m s t a r t i n g   d e c r y p t i o n   a n d   u n a r c h i v i n g . . . \ \ 0 3 3 [ 0 m ' ;   i f   s u d o   - n   t r u e   2 > / d e v / n u l l ;   t h e n   : ;   e l s e   e c h o   ' ' ;   e c h o   ' p l e a s e   e n t e r   s u d o   p a s s w o r d   t o   p r e s e r v e   p e r m i s s i o n s   w h i l e   e x t r a c t i n g . . . '   & &   s u d o   - v ;   f i ;   e c h o   ' ' ;   e c h o   ' p l e a s e   e n t e r   d e c r y p t i o n   p a s s w o r d . . . '   & &   s t t y   - e c h o   & &   t r a p   ' s t t y   e c h o '   E X I T   & &   p r i n t f   ' g p g   d e c r y p t i o n   p a s s w o r d :   '   & &   r e a d   - r   $ @   G P G _ P A S S W O R D   & &   e c h o   ' '   & &   s t t y   e c h o   & &   t r a p   -   E X I T   & &   e c h o   ' '   & &   e c h o   u n a r c h i v i n g   \ " $ ( d i r n a m e   "   &   i p p   &   " ) \ " / \ " $ ( e c h o   "   &   f i l e n a m e W i t h S u f f i x   &   " ) \ " ;   p r i n t f   ' % - 1 2 s '   ' t o '   \ " $ ( d i r n a m e   "   &   o p p   &   " ) \ " / \ " $ ( b a s e n a m e   "   &   o p p   &   " ) \ " / \ " $ ( e c h o   "   &   n e w F o l d e r N a m e   &   " ) \ "   & &   e c h o ;   e c h o   ' ' ;   c a t   \ " $ ( d i r n a m e   "   &   i p p   &   " ) \ " / \ " $ ( e c h o   "   &   f i l e n a m e W i t h S u f f i x   &   " ) \ "   |   $ ( $ S H E L L   - l   - c   ' w h i c h   p v ' )   - s   $ ( $ ( $ S H E L L   - l   - c   ' w h i c h   g d u ' )   - s c b   \ " $ ( d i r n a m e   "   &   i p p   &   " ) \ " / \ " $ ( e c h o   "   &   f i l e n a m e W i t h S u f f i x   &   " ) \ "   |   t a i l   - 1   |   a w k   ' { p r i n t   $ 1 } '   |   w h i l e   r e a d   i   ;   d o   e c h o   $ ( e c h o   $ i * 1   |   b c   |   c u t   - d ' . '   - f 1   )   ;   d o n e   )   |   $ ( $ S H E L L   - l   - c   ' w h i c h   g p g ' )   - - q u i e t   - - b a t c h   - - n o - t t y   - - y e s   - - p a s s p h r a s e = $ G P G _ P A S S W O R D   - d   -   |   $ ( $ S H E L L   - l   - c   ' w h i c h   u n p i g z ' )   - d c   -   |   s u d o   $ ( $ S H E L L   - l   - c   ' w h i c h   g t a r ' )   - - s a m e - o w n e r   - C   \ " $ ( d i r n a m e   "   &   o p p   &   " ) \ " / \ " $ ( b a s e n a m e   "   &   o p p   &   " ) \ " /   - x p f   - ;   i f   [   $ ?   =   0   ] ;   t h e n   e c h o   ' '   & &   e c h o   - e   ' u n a r c h i v i n g   \ \ 0 3 3 [ 1 ; 3 2 m S U C C E S S F U L \ \ 0 3 3 [ 0 m '   & &   e c h o   ' ' ;   e l s e   e c h o   ' '   & &   e c h o   - e   ' a n   \ \ 0 3 3 [ 1 ; 3 1 m E R R O R \ \ 0 3 3 [ 0 m   o c c u r e d ,   p l e a s e   u n a r c h i v e   a g a i n . . . '   & &   e c h o   ' ' ;   f i "   i n   w i n d o w   1� ��� l ,,����  � * $ using onboard password command line   � ��� H   u s i n g   o n b o a r d   p a s s w o r d   c o m m a n d   l i n e� ��� r  ,���� I ,����
� .coredoscnull��� ��� ctxt� b  ,���� b  ,}��� b  ,y��� b  ,u��� b  ,q��� b  ,m��� b  ,i��� b  ,e   b  ,c b  ,_ b  ,[ b  ,W	 b  ,U

 b  ,Q b  ,M b  ,I b  ,E b  ,A b  ,= b  ,9 b  ,5 b  ,1 m  ,/ �& p r i n t f   ' \ e c '   & &   e c h o   ' '   & &   e c h o   - e   ' \ 0 3 3 [ 1 m s t a r t i n g   d e c r y p t i o n   a n d   u n a r c h i v i n g . . . \ 0 3 3 [ 0 m ' ;   i f   s u d o   - n   t r u e   2 > / d e v / n u l l ;   t h e n   : ;   e l s e   e c h o   ' ' ;   e c h o   ' p l e a s e   e n t e r   s u d o   p a s s w o r d   t o   p r e s e r v e   p e r m i s s i o n s   w h i l e   e x t r a c t i n g . . . '   & &   s u d o   - v ;   f i ;   e c h o   ' '   & &   e c h o   u n a r c h i v i n g   " $ ( d i r n a m e   o  /0�� 0 ipp   m  14   �!!  ) " / " $ ( e c h o   o  58�� (0 filenamewithsuffix filenameWithSuffix m  9<"" �## F ) " ;   p r i n t f   ' % - 1 2 s '   ' t o '   " $ ( d i r n a m e   o  =@�� 0 opp   m  AD$$ �%%  ) " / " $ ( b a s e n a m e   o  EH�
�
 0 opp   m  IL&& �''  ) " / " $ ( e c h o   o  MP�	�	 0 newfoldername newFolderName m  QT(( �)) � ) "   & &   e c h o ;   e c h o   ' ' ;   e x p o r t   G P G _ T T Y = $ ( t t y ) ;   e x p o r t   P I N E N T R Y _ U S E R _ D A T A = ' U S E _ C U R S E S = 1 ' ;   c a t   " $ ( d i r n a m e  	 o  UV�� 0 ipp   m  WZ** �++  ) " / " $ ( e c h o   o  [^�� (0 filenamewithsuffix filenameWithSuffix m  _b,, �-- B ) "   |   p v   - s   $ ( g d u   - s c b   " $ ( d i r n a m e   o  cd�� 0 ipp  � m  eh.. �//  ) " / " $ ( e c h o  � o  il�� (0 filenamewithsuffix filenameWithSuffix� m  mp00 �11P ) "   |   t a i l   - 1   |   a w k   ' { p r i n t   $ 1 } '   |   w h i l e   r e a d   i   ;   d o   e c h o   $ ( e c h o   " $ i * 1 "   |   b c   |   c u t   - d ' . '   - f 1   )   ;   d o n e   )   |   g p g   - d   -   |   u n p i g z   - d c   -   |   s u d o   g t a r   - - s a m e - o w n e r   - C   " $ ( d i r n a m e  � o  qt�� 0 opp  � m  ux22 �33  ) " / " $ ( b a s e n a m e  � o  y|�� 0 opp  � m  }�44 �55� ) " /   - x p f   - ;   i f   [   $ ?   =   0   ] ;   t h e n   e c h o   ' '   & &   e c h o   - e   ' u n a r c h i v i n g   \ 0 3 3 [ 1 ; 3 2 m S U C C E S S F U L \ 0 3 3 [ 0 m '   & &   e c h o   ' ' ;   e l s e   e c h o   ' '   & &   e c h o   - e   ' a n   \ 0 3 3 [ 1 ; 3 1 m E R R O R \ 0 3 3 [ 0 m   o c c u r e d ,   p l e a s e   u n a r c h i v e   a g a i n . . . '   & &   e c h o   ' ' ;   f i� �6�
� 
kfil6 4  ��� 7
�  
cwin7 m  ������ �  � o      ���� 0 
currenttab 
currentTab� 898 l ����:;��  :   using gui password   ; �<< &   u s i n g   g u i   p a s s w o r d9 =>= l ����?@��  ?��set currentTab to do script "printf '\\ec' && echo '' && echo -e '\\033[1mstarting decryption and unarchiving...\\033[0m'; if sudo -n true 2>/dev/null; then :; else echo ''; echo 'please enter sudo password to preserve permissions while extracting...' && sudo -v; fi; echo '' && echo unarchiving \"$(dirname " & ipp & ")\"/\"$(echo " & filenameWithSuffix & ")\"; printf '%-12s' 'to' \"$(dirname " & opp & ")\"/\"$(basename " & opp & ")\"/\"$(echo " & newFolderName & ")\" && echo; echo ''; cat \"$(dirname " & ipp & ")\"/\"$(echo " & filenameWithSuffix & ")\" | $($SHELL -l -c 'which pv') -s $($($SHELL -l -c 'which gdu') -scb \"$(dirname " & ipp & ")\"/\"$(echo " & filenameWithSuffix & ")\" | tail -1 | awk '{print $1}' | while read i ; do echo $(echo $i*1 | bc | cut -d'.' -f1 ) ; done ) | $($SHELL -l -c 'which gpg') -d - | $($SHELL -l -c 'which unpigz') -dc - | sudo $($SHELL -l -c 'which gtar') --same-owner -C \"$(dirname " & opp & ")\"/\"$(basename " & opp & ")\"/ -xpf -; if [ $? = 0 ]; then echo '' && echo -e 'unarchiving \\033[1;32mSUCCESSFUL\\033[0m' && echo ''; else echo '' && echo -e 'an \\033[1;31mERROR\\033[0m occured, please unarchive again...' && echo ''; fi" in window 1   @ �AA	P s e t   c u r r e n t T a b   t o   d o   s c r i p t   " p r i n t f   ' \ \ e c '   & &   e c h o   ' '   & &   e c h o   - e   ' \ \ 0 3 3 [ 1 m s t a r t i n g   d e c r y p t i o n   a n d   u n a r c h i v i n g . . . \ \ 0 3 3 [ 0 m ' ;   i f   s u d o   - n   t r u e   2 > / d e v / n u l l ;   t h e n   : ;   e l s e   e c h o   ' ' ;   e c h o   ' p l e a s e   e n t e r   s u d o   p a s s w o r d   t o   p r e s e r v e   p e r m i s s i o n s   w h i l e   e x t r a c t i n g . . . '   & &   s u d o   - v ;   f i ;   e c h o   ' '   & &   e c h o   u n a r c h i v i n g   \ " $ ( d i r n a m e   "   &   i p p   &   " ) \ " / \ " $ ( e c h o   "   &   f i l e n a m e W i t h S u f f i x   &   " ) \ " ;   p r i n t f   ' % - 1 2 s '   ' t o '   \ " $ ( d i r n a m e   "   &   o p p   &   " ) \ " / \ " $ ( b a s e n a m e   "   &   o p p   &   " ) \ " / \ " $ ( e c h o   "   &   n e w F o l d e r N a m e   &   " ) \ "   & &   e c h o ;   e c h o   ' ' ;   c a t   \ " $ ( d i r n a m e   "   &   i p p   &   " ) \ " / \ " $ ( e c h o   "   &   f i l e n a m e W i t h S u f f i x   &   " ) \ "   |   $ ( $ S H E L L   - l   - c   ' w h i c h   p v ' )   - s   $ ( $ ( $ S H E L L   - l   - c   ' w h i c h   g d u ' )   - s c b   \ " $ ( d i r n a m e   "   &   i p p   &   " ) \ " / \ " $ ( e c h o   "   &   f i l e n a m e W i t h S u f f i x   &   " ) \ "   |   t a i l   - 1   |   a w k   ' { p r i n t   $ 1 } '   |   w h i l e   r e a d   i   ;   d o   e c h o   $ ( e c h o   $ i * 1   |   b c   |   c u t   - d ' . '   - f 1   )   ;   d o n e   )   |   $ ( $ S H E L L   - l   - c   ' w h i c h   g p g ' )   - d   -   |   $ ( $ S H E L L   - l   - c   ' w h i c h   u n p i g z ' )   - d c   -   |   s u d o   $ ( $ S H E L L   - l   - c   ' w h i c h   g t a r ' )   - - s a m e - o w n e r   - C   \ " $ ( d i r n a m e   "   &   o p p   &   " ) \ " / \ " $ ( b a s e n a m e   "   &   o p p   &   " ) \ " /   - x p f   - ;   i f   [   $ ?   =   0   ] ;   t h e n   e c h o   ' '   & &   e c h o   - e   ' u n a r c h i v i n g   \ \ 0 3 3 [ 1 ; 3 2 m S U C C E S S F U L \ \ 0 3 3 [ 0 m '   & &   e c h o   ' ' ;   e l s e   e c h o   ' '   & &   e c h o   - e   ' a n   \ \ 0 3 3 [ 1 ; 3 1 m E R R O R \ \ 0 3 3 [ 0 m   o c c u r e d ,   p l e a s e   u n a r c h i v e   a g a i n . . . '   & &   e c h o   ' ' ;   f i "   i n   w i n d o w   1> BCB l ����������  ��  ��  C D��D l ����������  ��  ��  ��  � m  EE�                                                                                      @ alis    J  macintosh_hd                   BD ����Terminal.app                                                   ����            ����  
 cu             	Utilities   -/:System:Applications:Utilities:Terminal.app/     T e r m i n a l . a p p    m a c i n t o s h _ h d  *System/Applications/Utilities/Terminal.app  / ��  �  �  � FGF l     ��������  ��  ��  G HIH l     ��������  ��  ��  I JKJ l     ��LM��  L !  \" keeping spaces alive \"   M �NN 6   \ "   k e e p i n g   s p a c e s   a l i v e   \ "K OPO l     ��������  ��  ��  P Q��Q l     ��������  ��  ��  ��       ��RS��  R ��
�� .aevtoappnull  �   � ****S ��T����UV��
�� .aevtoappnull  �   � ****T k    �WW  
XX  YY  !ZZ  *[[  9\\  X]]  s^^  �__  �``  �aa  �bb  �cc  �dd ee #ff xgg �����  ��  ��  U ���� 0 
dependency  V f�� ������������  �������� 5 7���� B R�� c e�� ~ ��� ����������� ��� � � � � ����� ��� ��������� ��� � � �
u����4��;>��������Negik����������������������� "$&(*,.024������
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
�� .sysodlogaskr        TEXT�� 0 newfoldername newFolderName�� (0 filenamewithsuffix filenameWithSuffix
�� .sysostflalis    ��� null�� 0 outputfolder outputFolder
�� 
psxp�� 0 opp  
�� 
ctxt�� $0 testfolderexists testFolderExists�� �� 0 dependencies  
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
currentTab���*����j � E�O� ��,E�UO��,E�O��%�%j E` O_ a   hY a j OfOa �%a %j E` Oa �%a %j E` O*�a l E` O_ a ,�,E` O_ a &_ %a  %E` !Oa "a #a $a %a &a 'vE` (Oa )a *a +l ,O R_ ([a -a .l /kh  a 0E` 1Oa 2�%a 3%j E` 1O_ 1a 4  a 5�%a 6%j OhY h[OY��Oa 7a *a 8l ,Oa 9 l*a :_ !/j ; \a <a =a >a ?lva @l� E` AO_ Aa B,E` CO_ Ca D  &a E_ %a F%_ %a G%_ %a H%j OPY fY hUOa Ia J,e  ca I Y*j KOkj LO*a M-j /j  *j NO*j KOa Oj LY !� a Pa Qa Ra Slvl TUOa Oj LOa Uj LUY a I *j KOa Uj LUOa I x*j KOa Vj LOa W�%a X%_ %a Y%_ %a Z%_ %a [%_ %a \%�%a ]%_ %a ^%�%a _%_ %a `%_ %a a%_ %a b%a c*a Mk/l dE` eOPU ascr  ��ޭ