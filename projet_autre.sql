DROP SCHEMA IF EXISTS projet CASCADE;
CREATE SCHEMA projet;

--====================--
--      TABLES        --
--====================--

CREATE TABLE projet.formations (
	id_formation SERIAL PRIMARY KEY,
	nom VARCHAR(100) NOT NULL CHECK (nom<>''),
	ecole VARCHAR(100) NOT NULL CHECK (ecole<>'')
);
CREATE TABLE projet.blocs (
	id_bloc SERIAL PRIMARY KEY,
	code_bloc VARCHAR(10) NOT NULL CHECK (code_bloc <> ''),
	nb_examens_pas_complet INTEGER NOT NULL CHECK (nb_examens_pas_complet>0),
	id_formation INTEGER REFERENCES projet.formations (id_formation) NOT NULL
);
CREATE TABLE projet.etudiants (
	id_etudiant SERIAL PRIMARY KEY,
	adresse_mail VARCHAR(50) UNIQUE CHECK (adresse_mail SIMILAR TO '_%._%@student.vinci.be'),
	nom_utilisateur VARCHAR(50) NOT NULL CHECK (nom_utilisateur<>''),
	mot_de_passe VARCHAR(50) NOT NULL CHECK (mot_de_passe<>''),
	id_bloc INTEGER REFERENCES projet.blocs (id_bloc) NOT NULL
);
CREATE TABLE projet.examens (
	code_examen CHARACTER(6) PRIMARY KEY CHECK (code_examen SIMILAR TO 'IPL[0-9][0-9][0-9]'),
	nom VARCHAR(50) NOT NULL CHECK (nom<>''),
	duree INTEGER NOT NULL CHECK (duree > 0),
	sur_machine BOOLEAN NOT NULL,
	date_heure_debut TIMESTAMP,
	complet BOOLEAN NOT NULL,
	id_bloc INTEGER REFERENCES projet.blocs (id_bloc) NOT NULL
);

--PROBLEME PAS DE CLÉ PRIMAIRE (A VERIFIER PAR CEZARY)
--Changement fait le 19/11 :
-- Rajout de la cle primaire

CREATE TABLE projet.inscriptions_examen(
	id_etudiant INTEGER REFERENCES projet.etudiants (id_etudiant) NOT NULL ,
	code_examen CHARACTER(6) REFERENCES projet.examens (code_examen) NOT NULL,
	PRIMARY KEY (id_etudiant, code_examen)
);


CREATE TABLE projet.locaux (
	id_local SERIAL PRIMARY KEY,
	nom_local VARCHAR(4) NOT NULL UNIQUE,
	nombre_places INTEGER NOT NULL CHECK (nombre_places>0),
	machines_disponibles BOOLEAN NOT NULL
);


--PROBLEME PAS DE CLÉ PRIMAIRE (A VERIFIER PAR CEZARY)
--Changement fait le 19/11 :
-- Rajout de la cle primaire

CREATE TABLE projet.attributions_locaux(
    id_local INTEGER REFERENCES projet.locaux (id_local) NOT NULL,
    code_examen CHARACTER(6) REFERENCES projet.examens (code_examen) NOT NULL,
	PRIMARY KEY (id_local,code_examen)
);
--====================--
--APPLICATION CENTRALE--
--====================--

--INSERTION LOCAL-- (A VERIFIER PAR CEZARY)

CREATE OR REPLACE FUNCTION projet.ajouterLocal(nom_loc VARCHAR(4), nb_places INTEGER, machines BOOLEAN) RETURNS BOOLEAN AS $$
DECLARE
BEGIN
	INSERT INTO projet.locaux VALUES (DEFAULT,nom_loc,nb_places, machines);
	RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

--INSERTION EXAMEN-- (A VERIFIER PAR CEZARY)

CREATE OR REPLACE FUNCTION projet.insererExamen(code_exam CHARACTER(6), nom VARCHAR(50), duree INTEGER, sur_machine BOOLEAN, 
											    cd_bloc VARCHAR (10)) RETURNS BOOLEAN AS $$
DECLARE
	variable_id_bloc INTEGER;
BEGIN
	--Recherche id de bloc
	SELECT projet.rechercheIdBloc(cd_bloc)INTO variable_id_bloc;

	--IF NOT EXISTS (SELECT * FROM projet.examens ex WHERE ex.code_examen = code_exam)THEN
		INSERT INTO projet.examens VALUES(code_exam, nom, duree, sur_machine, 
									NULL, false, variable_id_bloc);
		RETURN TRUE;
	--ELSE
	--	RAISE 'Examen % existe déjà dans la base de données',code_exam;
	--END IF;
	--RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

--ENCODER HEURE EXAMEN-- (TODO : Conflits Horaire)
CREATE OR REPLACE FUNCTION projet.encoderHeureDebut(code_exam CHARACTER(6), dateEtHeure TIMESTAMP) RETURNS BOOLEAN AS $$
DECLARE
	
	exam_date date;
BEGIN
	--Est ce qu'on verifie la dateEtHeure ???? Son format ?(a voir avec le coequipier)
	
	--DIFFÉRENTES VÉRIFICATIONS POUR VALIDATION DE L'HEURE POUR L'EXAMEN
	--Vérifier si y a des inscription pour examen
	IF NOT EXISTS(SELECT * FROM projet.inscriptions_examen inex WHERE inex.code_examen = code_exam)	THEN RAISE 'Aucun étudiant est inscrit a cet examen ou examen existe pas'; END IF;
	
	--Verifier si y a pas d'examen a ce jour pour ce bloc deja (fonction) !!!!! Exclure l'examen courant si changement de l'heure !!!
	
	
    exam_date = CAST(dateEtHeure AS DATE);
	
    --OK
	IF(SELECT projet.examenMemeDateBlocExistant(exam_date,code_exam)) THEN RAISE 'Il existe déjà un examen pour ce bloc a ce jour !';END IF;
	
	--LE CAS SI ON VEUT CHANGER L'HEURE EXAMEN ????? OK 
	IF (SELECT ex.date_heure_debut FROM projet.examens ex WHERE ex.code_examen = code_exam)IS NOT NULL THEN 
		IF EXISTS (SELECT * FROM projet.attributions_locaux atr WHERE atr.code_examen = code_exam) THEN RAISE 'On peut pas changer de date pour examen ou le local est deja reservé';
		END IF;
	END IF;
	--gerer les conflits horaire ????(TODO)
	UPDATE projet.examens SET date_heure_debut=dateEtHeure WHERE code_examen = code_exam;
	RETURN TRUE;
END;
$$ LANGUAGE plpgsql;


--RESERVER LOCAL (TODO)

CREATE OR REPLACE FUNCTION projet.reserverLocal (nom_local_a_reserv VARCHAR(4), code_exam CHARACTER(6))RETURNS BOOLEAN AS $$
DECLARE
BEGIN
    --Verification si pas deja reserver le local pour cet examen
    --Verification machine (sous-function??)
    --Verification si examen deja complet reserve
    --Verifier si examen a heure de debut
    --Verifier si le local n'est pas reserver pendant cette heure
END;
$$ LANGUAGE plpgsql;

--+++++++++++++++++++++--
--+++ VISUALISATION +++--
-------------------------

--Voir horaire examen pour un bloc particulier (TODO)
--CREATE OR REPLACE FUNCTION projet.voirHoraireBloc (cd_bloc varchar (10))RETURNS
--Voir toutes les reservation pour un local particulier (TODO)
--Voir tous les examens qui ne sont pas completements reservé (triee par code) (TODO)
--Voir le nombre d'examens qui ne sont pas completements reservé pour chaque bloc (TODO)




--=======================--
--APPLICATION UTILISATEUR--
--=======================--

--INSERTION UTILISATEUR-- (A VERIFIER PAR CEZARY)

CREATE OR REPLACE FUNCTION projet.insererUtilisateur (adresse_mail VARCHAR(50), nom VARCHAR(50), mot_de_passe VARCHAR(50), cd_bloc VARCHAR(10))RETURNS BOOLEAN AS $$
DECLARE
 	variable_id_bloc INTEGER;
BEGIN
	--Verification si le bloc passé en paramètre existe si non exception de clé étrangère invalide
	SELECT projet.rechercheIdBloc(cd_bloc) INTO variable_id_bloc;
	IF(variable_id_bloc!=0)THEN
		 INSERT INTO projet.etudiants VALUES (DEFAULT, adresse_mail, nom, mot_de_passe, variable_id_bloc);
		 RETURN TRUE;
	ELSE
		RAISE 'Le bloc existe pas';
	END IF;
	RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

--INSCRIPTION A UN EXAMEN-- (A VERIFIER PAR CEZARY)

CREATE OR REPLACE FUNCTION projet.inscriptionExamen (id_etud INTEGER, code_exam CHARACTER (6))RETURNS BOOLEAN AS $$
DECLARE
	variable_date timestamp;
BEGIN
	SELECT ex.date_heure_debut FROM projet.examens ex WHERE ex.code_examen = code_exam INTO variable_date;
	IF (variable_date NOTNULL)THEN 
		RAISE 'La date pour % est déjà fixée, les inscriptions sont cloturées',code_exam;
	ELSE
		INSERT INTO projet.inscriptions_examen VALUES (id_etud,code_exam);
		RETURN TRUE;
	END IF;
	RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

--Visualiser les examens (TODO)
--Inscrire a tous les examens de son bloc (TODO)
--Voir son horaire examen (TODO)

--======================--
--   AUTRES FONCTIONS   --
--======================--

-- RECHERCHE ID BLOC PAR SON CODE --
CREATE OR REPLACE FUNCTION projet.rechercheIdBloc (cd_bloc VARCHAR (10))RETURNS INTEGER AS $$
DECLARE
	variable_id_bloc INTEGER;
BEGIN
	SELECT bl.id_bloc FROM projet.blocs bl WHERE bl.code_bloc = cd_bloc INTO variable_id_bloc;
	IF(variable_id_bloc)IS NULL THEN RAISE 'Le bloc % existe pas',cd_bloc;END IF;
	RETURN variable_id_bloc;
END;
$$ LANGUAGE plpgsql;

-- NOMBRE D'ÉTUDIANTS POUR UN EXAMEN
--A VOIR SI GARDER CETTE FONCTION !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 
--utiliser avant pour voir si un etudiant inscrit pour examen (function encoderHeureExamen)
CREATE OR REPLACE FUNCTION projet.nombreInscrits (code_exam CHARACTER (6))RETURNS INTEGER AS $$
DECLARE
	variable_nombre_etudiants_inscrits INTEGER;
BEGIN
	SELECT COUNT(*) FROM projet.inscriptions_examen ins WHERE ins.code_examen = code_exam INTO variable_nombre_etudiants_inscrits;
	RETURN variable_nombre_etudiants_inscrits;
END;
$$ LANGUAGE plpgsql;

-- ID BLOC D'EXAMEN RECHERCHE
CREATE OR REPLACE FUNCTION projet.idBlocExamen (code_exam CHARACTER (6))RETURNS INTEGER AS $$
DECLARE
	id_bloc_ex INTEGER;
BEGIN
	SELECT id_bloc FROM projet.examens ex WHERE code_examen = code_exam INTO id_bloc_ex;
	IF (id_bloc_ex IS NOT NULL) THEN 	
		RETURN id_bloc_ex;	
	ELSE
		RAISE 'Examen % existe pas !',code_examen;
	END IF;
END;
$$ LANGUAGE plpgsql;

-- VERIFICATION SI A LA DATE DONNÉ, IL EXISTE DEJA UN EXAMEN POUR CE BLOC --
-- Prend en paramètre une date (pas de l'heure) et un bloc
--J'ai fait testé cette function le 20/11 normalement tout est bon 
CREATE OR REPLACE FUNCTION projet.examenMemeDateBlocExistant (la_date DATE, code_exam CHARACTER(6))RETURNS BOOLEAN AS $$
DECLARE
    id_bloc_exam INTEGER;
BEGIN
    SELECT projet.idBlocExamen(code_exam) INTO id_bloc_exam;
	IF NOT EXISTS (SELECT * 
				   FROM projet.examens ex 
				   WHERE ex.date_heure_debut IS NOT NULL 
				   AND ex.date_heure_debut::date = la_date 
				   AND ex.id_bloc = id_bloc_exam AND ex.code_examen != code_exam) THEN RETURN FALSE; END IF;
	RETURN TRUE;												   
END;
$$ LANGUAGE plpgsql;

--====================--
----======TEST======----
--====================--

INSERT INTO projet.formations VALUES (default, 'Informatique de gestion', 'Paul Lambin');
INSERT INTO projet.blocs VALUES (default,'BIN1', 10,4);
SELECT projet.ajouterLocal('A025',25,true);
SELECT projet.insererExamen('IPL001', 'Examen', 150, true,'BIN1');
SELECT projet.insererUtilisateur('mati.rydz@student.vinci.be','piwreq','dbgtppp','BIN1');
INSERT INTO projet.examens VALUES ('IPL002','examen de java','150', true, null, false, 1);
SELECT * FROM projet.examens;
--UPDATE projet.examens SET date_heure_debut = '2019-07-01 15:10:00' WHERE code_examen = 'IPL001';
SELECT * FROM projet.examens;
SELECT projet.inscriptionExamen(1,'IPL001');
SELECT * FROM projet.inscriptions_examen;
SELECT * FROM projet.inscriptions_examen;
SELECT projet.nombreInscrits('IPL002');
--SELECT projet.encoderHeureDebut('IPL002','1/1/2020');SELECT * FROM projet.examens;--UPDATE projet.examens SET date_heure_debut = '2019-07-01 15:10:00' WHERE code_examen = 'IPL002';
--SELECT * FROM projet.examens;SELECT projet.inscriptionExamen(1,'IPL002');
SELECT projet.rechercheIdBloc('BIN1');
SELECT projet.rechercheIdBloc('BIN2');

--Test Function examenMemeDateBlocExistant :
SELECT projet.insererExamen('IPL002','PHP Examen',150,true,'BIN1');
INSERT INTO projet.blocs VALUES (default,'BIN2',10,4);
SELECT projet.insererExamen('IPL103','WEB Examen',150,true,'BIN2');
UPDATE projet.examens SET date_heure_debut = null WHERE code_examen = 'IPL001';
SELECT projet.examenMemeDateBlocExistant ('26/10/2020', 4); --TRUE
UPDATE projet.examens SET date_heure_debut = '26/10/2020 15:10:00' WHERE code_examen = 'IPL103';
SELECT projet.examenMemeDateBlocExistant ('26/10/2020',4);

--Test function encoder heure debut
SELECT projet.encoderHeureDebut('IPL002','25/10/2020 15:10:00');--erreur
SELECT projet.encoderHeureDebut('IPL002','25/10/2020 16:10:00');--erreur
SELECT projet.encoderHeureDebut('IPL002','26/10/2020 16:10:00');--valider

SELECT projet.encoderHeureDebut('IPL002','25/10/2020 16:10:00');--erreur
SELECT projet.encoderHeureDebut('IPL002','26/10/2020 16:10:00');--valider
SELECT projet.encoderHeureDebut('IPL002','27/10/2020 16:10:00');--valider
INSERT INTO projet.locaux VALUES (default,'A026',20,true);
INSERT INTO projet.attributions_locaux VALUES(1,'IPL002');
DROP TABLE projet.attribution_locaux;
SELECT projet.encoderHeureDebut('IPL002','27/10/2020 17:10:00');--ok