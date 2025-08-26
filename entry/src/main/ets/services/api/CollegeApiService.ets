import { ApiResponse, HttpService } from './HttpService';
import { ClassInfo, College, Major } from '../../models/CollegeModels';


interface getAllMajorsParam {
  collegeId: string;
}

interface getAllClassesParam {
  majorId: string;
}

export class CollegeApiService {
  private static instance: CollegeApiService;
  private httpService: HttpService;

  private constructor() {
    this.httpService = HttpService.getInstance();
  }

  public static getInstance(): CollegeApiService {
    if (!CollegeApiService.instance) {
      CollegeApiService.instance = new CollegeApiService();
    }
    return CollegeApiService.instance;
  }

  public async getAllColleges(): Promise<ApiResponse<College[]>> {
    return this.httpService.get<null, College[]>('/classes/getAllColleges');
  }

  public async getAllMajors(collegeId: string): Promise<ApiResponse<Major[]>> {
    const param: getAllMajorsParam = { collegeId: collegeId };
    return this.httpService.get<getAllMajorsParam, Major[]>('/classes/getAllMajorsByCollege', param);
  }

  public async getAllClasses(majorId: string): Promise<ApiResponse<ClassInfo[]>> {
    const param: getAllClassesParam = { majorId: majorId };
    return this.httpService.get<getAllClassesParam, ClassInfo[]>('/classes/getAllClassesByMajor', param);
  }
}