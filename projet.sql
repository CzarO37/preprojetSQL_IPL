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
	code_bloc VARCHAR(10) REFERENCES projet.blocs (id_bloc) NOT NULL
);
CREATE TABLE projet.inscriptions_examen(
	id_etudiant INTEGER REFERENCES projet.etudiants (id_etudiant) NOT NULL
	id_examen INTEGER NOT NULL projet.examens (code_examens) NOT NULL	
);