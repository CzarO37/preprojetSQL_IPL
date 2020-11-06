DROP SCHEMA IF EXISTS projet CASCADE;
CREATE SCHEMA projet;
CREATE TABLE projet.formations (
	id_formations SERIAL PRIMARY KEY,
	nom VARCHAR(100) NOT NULL CHECK (nom<>''),
	prenom VARCHAR(100) NOT NULL CHECK (prenom<>'')
);
CREATE TABLE projet.blocs (
	id_bloc SERIAL PRIMARY KEY,
	code_bloc VARCHAR(10) NOT NULL CHECK (code_bloc <> ''),
	nb_examens_pas_complet INTEGER NOT NULL CHECK (nb_examens_pas_complet>0),
	id_formation INTEGER REFERENCES projet.formations (id_formations) NOT NULL
);
CREATE TABLE projet.etudiants (
	id_etudiant SERIAL PRIMARY KEY,
	nom VARCHAR(50) NOT NULL CHECK (nom<>''),
	prenom VARCHAR(50) NOT NULL CHECK (prenom<>''),
	mot_de_passe VARCHAR(50) NOT NULL CHECK (mot_de_passe<>''),
	id_bloc INTEGER REFERENCES projet.blocs (id_bloc) NOT NULL
);
CREATE TABLE projet.examens (
	code_examen CHARACTER(6) PRIMARY KEY CHECK (code_examen SIMILAR TO 'IPL[0-9][0-9][0-9]'),
	nom VARCHAR(50) NOT NULL CHECK (nom<>''),
	duree INTEGER NOT NULL CHECK (duree > 0),
	sur_machine BOOLEAN NOT NULL,
	heure_debut TIMESTAMP,
	complet BOOLEAN NOT NULL,
	id_bloc INTEGER REFERENCES projet.blocs (id_bloc) NOT NULL
);
CREATE TABLE projet.inscriptions_examen(
	id_etudiant INTEGER REFERENCES projet.etudiants (id_etudiant) NOT NULL,
	code_examen CHARACTER(6) REFERENCES projet.examens (code_examen) NOT NULL,
	id_bloc INTEGER REFERENCES projet.blocs (id_bloc) NOT NULL
);
CREATE TABLE projet.attribution_locaux(
	code_local INTEGER REFERENCES projet.locaux (id_local) NOT NULL,
	code_examen CHARACTER(6) REFERENCES projet.examens (code_examen) NOT NULL
)