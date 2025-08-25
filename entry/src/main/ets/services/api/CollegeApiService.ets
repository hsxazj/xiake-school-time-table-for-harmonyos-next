import { ApiResponse, HttpService } from './HttpService';
import { ClassInfo, College, Major } from '../../models/CollegeModels';

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
    return this.httpService.get<College[]>('/classes/getAllColleges');
  }

  public async getAllMajors(collegeId: string): Promise<ApiResponse<Major[]>> {
    const params: Record<string, Object> = {};
    params['collegeId'] = collegeId;
    return this.httpService.get<Major[]>('/classes/getAllMajorsByCollege', params);
  }

  public async getAllClasses(majorId: string): Promise<ApiResponse<ClassInfo[]>> {
    const params: Record<string, Object> = {};
    params['majorId'] = majorId;
    return this.httpService.get<ClassInfo[]>('/classes/getAllClassesByMajor', params);
  }
}