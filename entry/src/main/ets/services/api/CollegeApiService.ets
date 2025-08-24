import { HttpService } from './HttpService';
import { ApiResponse, ClassInfo, College, Major } from '../../models/CollegeModels';

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

  public async getAllMajors(collegeId: number): Promise<ApiResponse<Major[]>> {
    const params: Record<string, Object> = {};
    params['collegeId'] = collegeId;
    return this.httpService.get<Major[]>('/classes/getAllMajorsByCollege', params);
  }

  public async getAllClasses(majorId: number): Promise<ApiResponse<ClassInfo[]>> {
    const params: Record<string, Object> = {};
    params['majorId'] = majorId;
    return this.httpService.get<ClassInfo[]>('/classes/getAllClassesByMajor', params);
  }
}