export interface College {
  collegeId: string;
  collegeName: string;
}

export interface Major {
  majorId: string;
  majorName: string;
  collegeId: string;
}

export interface ClassInfo {
  classId: string;
  className: string;
  majorId: string;
}

export interface UserSelection {
  collegeId: string;
  collegeName: string;
  majorId: string;
  majorName: string;
  classId: string;
  className: string;
}