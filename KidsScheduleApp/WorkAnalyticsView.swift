import SwiftUI
import Charts

struct WorkAnalyticsView: View {
    @StateObject private var workManager = WorkManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let analytics = workManager.workAnalytics {
                        weeklyTrendSection(analytics.weeklyTrend)
                        categoryBreakdownSection(analytics.categoryBreakdown)
                        insightsSection(analytics.productivityInsights)
                        recommendationsSection(analytics.recommendations)
                    } else {
                        loadingView
                    }
                }
                .padding()
            }
            .navigationTitle("📊 工作分析")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("刷新") {
                        workManager.refreshWorkData()
                    }
                }
            }
            .onAppear {
                workManager.refreshWorkData()
            }
        }
    }
    
    // MARK: - 周度趋势
    private func weeklyTrendSection(_ weeklyData: [WeeklyData]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.blue)
                Text("📈 四周工作趋势")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if weeklyData.isEmpty {
                Text("暂无趋势数据")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 16) {
                    // 完成任务数趋势
                    trendChart(
                        title: "完成任务数",
                        data: weeklyData.map { ($0.weekStart, Double($0.tasksCompleted)) },
                        color: .green
                    )
                    
                    // 工作时长趋势
                    trendChart(
                        title: "工作时长 (小时)",
                        data: weeklyData.map { ($0.weekStart, $0.totalHours) },
                        color: .blue
                    )
                    
                    // 平均进度趋势
                    trendChart(
                        title: "平均进度 (%)",
                        data: weeklyData.map { ($0.weekStart, $0.averageProgress) },
                        color: .purple
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private func trendChart(title: String, data: [(Date, Double)], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            // 简化的图表显示（使用文本表示）
            HStack {
                ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                    VStack(spacing: 4) {
                        Text(String(format: "%.1f", item.1))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(color)
                        
                        Rectangle()
                            .fill(color)
                            .frame(width: 20, height: max(4, item.1 * 2))
                            .cornerRadius(2)
                        
                        Text("W\(index + 1)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    if index < data.count - 1 {
                        Spacer()
                    }
                }
            }
            .frame(height: 80)
        }
    }
    
    // MARK: - 分类统计
    private func categoryBreakdownSection(_ categories: [CategoryData]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.pie")
                    .foregroundColor(.orange)
                Text("📊 分类统计")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if categories.isEmpty {
                Text("暂无分类数据")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(Array(categories.enumerated()), id: \.offset) { index, category in
                    categoryCard(category)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private func categoryCard(_ category: CategoryData) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(category.category)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(category.taskCount)个任务")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(String(format: "%.1f", category.timeSpent))h")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                
                Text("\(String(format: "%.1f", category.completionRate))%")
                    .font(.caption)
                    .foregroundColor(category.completionRate >= 80 ? .green : .orange)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - 洞察分析
    private func insightsSection(_ insights: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb")
                    .foregroundColor(.yellow)
                Text("💡 洞察分析")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            ForEach(insights, id: \.self) { insight in
                HStack(alignment: .top, spacing: 12) {
                    Circle()
                        .fill(Color.yellow.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .padding(.top, 6)
                    
                    Text(insight)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - 改进建议
    private func recommendationsSection(_ recommendations: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "target")
                    .foregroundColor(.green)
                Text("🎯 改进建议")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            ForEach(Array(recommendations.enumerated()), id: \.offset) { index, recommendation in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Color.green)
                        .clipShape(Circle())
                    
                    Text(recommendation)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - 加载视图
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("正在分析工作数据...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    WorkAnalyticsView()
}
