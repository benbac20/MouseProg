Unit USouris;

{prob: ResturerEtatSouris;}

Interface

Uses
  dos;

procedure TesterDriver;
procedure ActiverDriver;
procedure DesactiverDriver;
procedure LirePosCurseur;
procedure DefinirPosCurseur;
procedure LireDistance;
procedure DefinirZoneDeplacement;
procedure DefinirZoneExclusion;
procedure AfficherCurseur;
procedure CacherCurseur;
procedure DessinerCurseurGraph;
procedure DessinerCurseurTexte;
procedure LireSensibiliteSouris;
procedure DefinirSensibiliteSouris;
function LireTailleBuffer: word;
procedure SauverEtatSouris;
{procedure RestaurerEtatSouris;}

const
  Logiciel = 0;
  Materiel = 1;

  GetMaxX = 80;
  GetMaxY = 25;

var
  Driver : record {les infos du driver}
    DrvExiste: boolean;
    Version: string;
    TypeDrv: string;
    Irq: byte;
  end;

  Souris : record {les infos de la souris}
    NBrBtns: byte;
    EtatBtn1, EtatBtn2: byte;
    AncienEB1, AncienEB2: byte;
  end;

  Curseur : record {les infos du curseur}
    Seuil: word;
    AncienSeuil: word;
    X,Y: word;
    DistanceX, DistanceY: word;
    Sensibilite: byte;
    AncienSensibilite: byte;
    TypeCurseur: word;
    Operand1, Operand2: word;
  end;

  ZoneExclusion: record {la zone d'exclusion}
    MinX, MinY, MaxX, MaxY: word;
  end;

  ZoneDeplacement: record {la zone de deplacement}
    MinX, MinY, MaxX, MaxY: word;
  end;

  ZoneExit: record {la zone d'exit}
    MinX, MinY, MaxX, MaxY: word;
  end;

  reg: registers; {les registres du travaille}
  {CurseurType: boolean;}

  BufferEtatSouris: array[0..999] of word; {Le buffer d'�tat de la souris}
  TailleBuffer: word; {La taille du buffer d'�tat de la souris}

Implementation

procedure TesterDriver;
{R�initialise et lire les infos de la souris}
{*******************************************************
Int33h, Fct 00h   R�initialisation du driver de souris
Entr�e :AX = 0000h
Sortie :
	AX = FFFFh : un driver de souris est install�
	BX = Nombre de boutons de la Souris
	AX = 0000h : erreur, aucun driver n'est install�
********************************************************
Int 33h, Fct 24h   Lire le type de souris
Entr�e :AX=0024h
Sortie :
	BH = Partie enti�re du num�ro de version
	BL = Partie d�cimale du num�ro de version
	CH = Type de souris
		1 = Souris bus
		2 = Souris s�rie
		3 = Souris InPort
		4 = Souris PS/2
		5 = Souris HP
	CL = Num�ro IRQ
		0 = PS/2
		2, 3, 4, 5 ou 7 = Num�ro PC
********************************************************}
var
  VerH, VerL: string;
begin
  with Driver do
    with reg do
     begin
       ax := 0;
       intr ($33, reg);
       Souris.NbrBtns := bl;
       DrvExiste := (ax <> 0);
       if not DrvExiste then exit;

       ax := $24;
       intr($33, reg);
       str(bl, VerL);
       str(bh, VerH);
       Version := VerH + '.' + VerL;
       Irq := cl;
       case ch of
         1: TypeDrv :='Souris Bus';
         2: TypeDrv :='Souris S�rie';
         3: TypeDrv :='Souris InPort';
         4: TypeDrv :='Souris PS/2';
         5: TypeDrv :='Souris HP';
       end;
     end;
end;

procedure ActiverDriver;
{Activer le driver}
{********************************************************
Int 33h, Fct 20h    Activer le driver de la souris
Entr�e :AX = 0020h
Sortie :
	AX = FFFFh : Erreur
	AX = 0020h : Tout va bien
********************************************************}
begin
  reg.ax := $20;
  intr($33, reg);
end;

Procedure DesactiverDriver;
{D�sactiver le driver}
{********************************************************
Int 33h, Fct 1Fh    D�sactiver le driver de la souris
Entr�e :AX = 001Fh
Sortie :
	AX = FFFFh : Erreur
	AX = 001Fh : Tout va bien
	ES:BX = Adresses de segment et d'offset du driver de souris ant�rieur
********************************************************}
begin
  reg.ax := $1f;
  intr($33, reg);
end;

procedure LirePosCurseur;
{Lire la position et l'�tat du boutons}
{********************************************************
Int 33h, Fct 03h   Lire la position et l'�tat des boutons de la souris
Entr�e :AX = 0003h
Sortie :
	BX = Etat des boutons de la Souris
		Bit Signification
		0   1 = bouton gauche de la souris appuy�
		1   1 = bouton droit de la souris appuy�
		2   1 = bouton central de la souris appuy�
		Autre	Aucune
	CX = Position horizontale de la Souris
	DX = Position verticale de la souris
********************************************************}
begin
  with Souris do
    with Curseur do
      with reg do
        begin
          ax := $3;
          intr($33, reg);
	  EtatBtn1 := bl and 1;
   	  EtatBtn2 := bl and 2;
          x := cx;
          y := dx;
        end;
end;

procedure DefinirPosCurseur;
{D�placer le curseur}
{********************************************************
Int 33h, Fct 04h    D�placement du curseur de la souris
Entr�e :
	AX = 0004h
	CX = Position horizontale de la Souris
	DX = Position verticale de la souris
Sortie :Aucune
********************************************************}
begin
  with Curseur do
    with reg do
      begin
        ax := $04;
        cx := x * 8;
        dx := y * 7;
      end;
  intr($33, reg);
end;

procedure LireDistance;
{Lire la distance de d�placement}
{********************************************************
Int 33h, Fct 0Bh    Lire les distances de d�placement
Entr�e :AX = 000Bh
Sortie :
	CX = Distance horizontale
	DX = Distance verticale
********************************************************}
begin
  with reg do
    with Curseur do
      begin
        ax := $0b;
        intr($33, reg);
        DistanceX := cx;
        DistanceY := dx;
    end;
end;

procedure DefinirZoneDeplacement;
{Fixer la zone de deplacement}
{********************************************************
Int 33h, Fct 07h (08h)    D�finir la zone de d�placement horizontale (verticale ) pour le curseur de la souris
Entr�e :
	AX = 0007h (0008h)
	CX = position horizontale minimale de la souris
	DX = position horizontale maximale de la souris
Sortie :Aucune
********************************************************}
begin
  with ZoneDeplacement do
    with reg do
      begin
        ax := $07;
        cx := MinX*8;
        dx := MaxX*8;
        intr($33, reg);

        ax := $08;
        cx := MinY*7;
        dx := MaxY*7;
        intr($33, reg);
      end;
end;

procedure DefinirZoneExclusion;
{Fixer la zone d'exclusion}
{********************************************************
Int 33h, Fct 10h    D�finir la zone d'exclusion
Entr�e :
	AX = 0010h
	CX = Ordonn�e X du coin sup�rieur gauche
	DX = Ordonn�e Y du coin sup�rieur gauche
	SI = Ordonn�e X du coin inf�rieur droit
	DI = Ordonn�e Y du coin inf�rieur droit
Sortie :Aucune
********************************************************}
begin
  with ZoneExclusion do
    with reg do
    begin
      ax := $10;
      cx := MinX*8;
      dx := MinY*7;
      si := MaxX*8;
      di := MaxY*7;
    end;
  intr($33, reg);
end;

procedure AfficherCurseur;
{Afficher le curseur}
{********************************************************
Int 33h, Fct 01h    Afficher le curseur de la souris
Entr�e :AX = 0001h
Sortie :Aucune
********************************************************}
begin
  reg. ax := 1;
  intr($33, reg);
  DefinirZoneExclusion;
end;

procedure CacherCurseur;
{Cacher le curseur}
{********************************************************
Int 33h, Fct 02h    Masquer le curseur de la souris
Entr�e :AX = 0002h
Sortie :Aucune
********************************************************}
begin
  reg. ax := 2;
  intr($33, reg);
end;

procedure DessinerCurseurGraph;
{Afficher le curseur en mode graphique}
{********************************************************
Int 33h, Fct 09h    D�finit le curseur de la souris en mode graphique
Entr�e :
	AX = 0009h
	BX = Distance du point de r�f�rence au bord gauche du tableau de bits
	CX = Distance du point de r�f�rence au bord sup�rieur du tableau de bits
	ES:DX	= Adresses de segment et d'offset du tableau de bits dans la m�moire
Sortie :Aucune
********************************************************}
begin
  CacherCurseur;
  with Curseur do
    with reg do
      begin
        ax := $09;
        bx := 0;
        cx := 0;
        es := seg(TypeCurseur);
        dx := ofs(TypeCurseur);
      end;
  intr($33, reg);
  AfficherCurseur;
end;

procedure DessinerCurseurTexte;
{Afficher le curseur en mode texte}
{********************************************************
Int 33h, Fct 0Ah    D�finit le curseur de la souris en mode de texte
Entr�e :
	AX = 000Ah
	BX = Type de curseur de la Souris
		0 = curseur logiciel
		1 = curseur �lectronique
	CX = Masque AND pour le curseur logiciel ou la ligne de d�part du curseur �lectronique
	DX = Masque XOR pour le curseur logiciel ou la ligne finale du curseur �lectronique
Sortie :Aucune
********************************************************}
begin
  CacherCurseur;
  with reg do
    with Curseur do
      begin
        ax := $0a;
        bx := TypeCurseur;
        cx := Operand1;
        dx := Operand2;
      end;
  intr($33, reg);
  AfficherCurseur;
end;

procedure LireSensibiliteSouris;
{Lire la sensibilitit� de la souris}
{********************************************************
Int 33h, Fct 1Bh    Lire la sensibilit� de la souris
Entr�e :AX = 001Bh
Sortie :
	BX = Nombre de mickeys repr�sentant huit points horizontalement
	CX = Nombre de mickeys repr�sentant huit points verticalement
	DX = Seuil pour le doublement de la vitesse de la souris
********************************************************}
begin
  with Curseur do
    with reg do
      begin
        ax := $1b;
        intr($33, reg);
        {Sensibilite := bx;}
        Sensibilite := cx;
        Seuil := dx;
      end;
end;

procedure DefinirSensibiliteSouris;
{Fixer la sensibilite de la souris}
{********************************************************
Int 33h, Fct 1Ah    D�finir la sensibilit� de la souris
Entr�e :
	AX = 001Ah
	BX = Nombre de mickeys repr�sentant huit points horizontalement
	CX = Nombre de mickeys repr�sentant huit points verticalement
	DX = Seuil pour le doublement de la vitesse de la souris
Sortie :Aucune
********************************************************}
begin
  with Curseur do
    with reg do
      begin
        ax := $1a;
        bh := 0;
        bl := Sensibilite;
        ch := 0;
        cl := Sensibilite;
        dx := Seuil;
      end;
  intr($33, reg);
end;

function LireTailleBuffer: word;
{Lire la taille du buffer d'�tat de la souris}
{********************************************************
Int 33h, Fct 15h    Lire la taille du buffer d'�tat de la souris
Entr�e : AX = 0015h
Sortie : BX = Taille du buffer d'�tat de la souris en octets
********************************************************}
begin
  with reg do
    begin
      ax := $15;
      intr($33, reg);
      TailleBuffer := bx;
    end;
  LireTailleBuffer := TailleBuffer;
end;

procedure SauverEtatSouris;
{Sauvegarder �tat de la souris}
{********************************************************
Int 33h, Fct 16h    Sauvegarder �tat de la souris
Entr�e :
	AX = 0016h
	ES:DX = Adresses de segment et d'offset du buffer
Sortie :Aucune
********************************************************}
begin
  with reg do
    begin
      ax := $16;
      bx := TailleBuffer;
      es := seg(BufferEtatSouris);
      dx := ofs(BufferEtatSouris);
    end;
  intr($33, reg);
end;

(*procedure RestaurerEtatSouris;
{Restaurer l'�tat de la souris}
{********************************************************
Int 33h, Fct 17h    Restaurer l'�tat de la souris
Entr�e :
	AX = 0017h
	ES:DX = Adresses de segment et d'offset du buffer d'�tat de la souris
Sortie :Aucune
********************************************************}
begin
  with reg do
    begin
      ax := $17;
      bx := TailleBuffer;
      es :=  seg(BufferEtatSouris);
      dx :=  ofs(BufferEtatSouris);
    end;
  intr($33, reg);
end;*)

end.